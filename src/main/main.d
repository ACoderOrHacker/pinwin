module main.main;

version (Windows) {

import std.conv;
import core.sys.windows.windows;
import core.sys.windows.shellapi;
import core.sys.windows.psapi;
import core.stdc.string;
import core.stdc.stdio;
import pinwin.pinwin;

pragma(lib, "user32.lib");
pragma(lib, "shell32.lib");
pragma(lib, "psapi.lib");

enum TRAY_UID = 1001;
enum WM_TRAYICON = WM_USER + 1;
enum ID_EXIT = 1;
enum PROCESS_MENU_BASE = 1000;
enum MAX_PROCESS = 40;
enum REFRESH_INTERVAL = 2000; // ms

HINSTANCE g_hInstance;
HWND g_hWnd;
HMODULE g_hRes;

struct ProcInfo {
    DWORD pid;
    HWND hwnd;
    char[64] name;
    bool checked;
}

ProcInfo[] g_processList;

extern (Windows)
nothrow BOOL enumWindowsProc(HWND hwnd, LPARAM lParam) {
    DWORD pid;
    GetWindowThreadProcessId(hwnd, &pid);
    char[256] title;
    GetWindowTextA(hwnd, title.ptr, cast(int)title.length);
    if (IsWindowVisible(hwnd) && title[0]) {
        auto pid2hwnd = cast(HWND[DWORD]*)lParam;
        (*pid2hwnd)[pid] = hwnd;
    }
    return 1;
}

nothrow void updateProcessList()
{
    DWORD[1024] pids;
    DWORD needed;
    if (!EnumProcesses(pids.ptr, pids.length * DWORD.sizeof, &needed)) return;
    size_t procCount = needed / DWORD.sizeof;

    HWND[DWORD] pid2hwnd;
    EnumWindows(&enumWindowsProc, cast(LPARAM)&pid2hwnd);

    ProcInfo[] newList;
    foreach(i; 0 .. procCount) {
        DWORD pid = pids[i];
        if (pid == 0 || !(pid in pid2hwnd)) continue;

        HANDLE hProc = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, 0, pid);
        if (hProc !is null) {
            char[64] name;
            if (GetModuleBaseNameA(hProc, null, name.ptr, cast(DWORD)name.length)) {
                bool checked = false;
                foreach(p; g_processList)
                    if (p.pid == pid && p.name == name)
                        checked = p.checked;
                newList ~= ProcInfo(pid, pid2hwnd[pid], name, checked);
            }
            CloseHandle(hProc);
        }
    }
    g_processList = newList;
}

nothrow void showTrayMenu(HWND hwnd, POINT* pt)
{
    HMENU hMenu = CreatePopupMenu();
    HMENU hSubMenu = CreatePopupMenu();

    int idx = 0;
    foreach(p; g_processList) {
        char[128] txt;
        snprintf(txt.ptr, txt.length, "%s (%u)", p.name.ptr, p.pid);
        UINT flags = MF_STRING;
        if (p.checked) flags |= MF_CHECKED;
        AppendMenuA(hSubMenu, flags, PROCESS_MENU_BASE + idx, txt.ptr);
        idx++;
    }
    if (idx == 0)
        AppendMenuA(hSubMenu, MF_GRAYED, 0, "<no process>");

    AppendMenuA(hMenu, MF_POPUP, cast(UINT_PTR)hSubMenu, "Process List");
    AppendMenuA(hMenu, MF_SEPARATOR, 0, null);
    AppendMenuA(hMenu, MF_STRING, ID_EXIT, "Exit");

    SetForegroundWindow(hwnd);
    TrackPopupMenu(hMenu, TPM_BOTTOMALIGN | TPM_LEFTALIGN, pt.x, pt.y, 0, hwnd, null);
    DestroyMenu(hMenu);
}

nothrow void handleProcessMenu(int idx)
{
    if (idx < 0 || idx >= g_processList.length)
        return;
    g_processList[idx].checked = !g_processList[idx].checked;
    if (g_processList[idx].checked) {
        pinWindow(g_processList[idx].hwnd);
    } else {
        unpinWindow(g_processList[idx].hwnd);
    }
}

extern (Windows)
nothrow LRESULT WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
        case WM_CREATE:
            NOTIFYICONDATAA nid = void;
            nid.cbSize = NOTIFYICONDATAA.sizeof;
            nid.hWnd = hwnd;
            nid.uID = TRAY_UID;
            nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
            nid.uCallbackMessage = WM_TRAYICON;
            nid.hIcon = LoadIconW(g_hRes, "IDI_TRAY_ICON");
            strncpy(cast(char*)nid.szTip.ptr, "Pinwin", nid.szTip.length - 1);
            Shell_NotifyIconA(NIM_ADD, &nid);
            updateProcessList();
            SetTimer(hwnd, 1, REFRESH_INTERVAL, null);
            break;
        case WM_TIMER:
            updateProcessList();
            break;
        case WM_TRAYICON:
            if (lParam == WM_RBUTTONUP) {
                POINT pt;
                GetCursorPos(&pt);
                showTrayMenu(hwnd, &pt);
            }
            break;
        case WM_COMMAND:
            if (wParam == ID_EXIT) {
                PostQuitMessage(0);
            } else {
                int idx = cast(int)wParam - PROCESS_MENU_BASE;
                if (idx >= 0 && idx < g_processList.length)
                    handleProcessMenu(idx);
            }
            break;
        case WM_DESTROY:
            NOTIFYICONDATAA nid = void;
            nid.cbSize = NOTIFYICONDATAA.sizeof;
            nid.hWnd = hwnd;
            nid.uID = TRAY_UID;
            Shell_NotifyIconA(NIM_DELETE, &nid);
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProcA(hwnd, msg, wParam, lParam);
    }

    return 0;
}

extern (Windows)
void WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    g_hInstance = hInstance;
    g_hRes = LoadLibraryA("resources.dll");
    if (GetLastError() != ERROR_SUCCESS) {
        MessageBoxA(null, "Cannot load resources", "Pinwin", MB_OK | MB_ICONERROR);
        return;
    }

    WNDCLASSA wc;
    wc.lpfnWndProc = &WndProc;
    wc.hInstance = g_hInstance;
    wc.lpszClassName = "Pinwin";
    wc.hIcon = LoadIconW(g_hRes, "IDI_TRAY_ICON");
    if (!RegisterClassA(&wc)) 
        MessageBoxA(null, "unregistered class", 
            "Pinwin", MB_OK | MB_ICONERROR);

    g_hWnd = CreateWindowExA(
        0,
        "Pinwin",
        "Pinwin",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 400, 200,
        null, null, g_hInstance, null
    );

    ShowWindow(g_hWnd, SW_HIDE);

    MSG msg;
    while (GetMessageA(&msg, null, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessageA(&msg);
    }

    FreeLibrary(g_hRes);
}
} else {
    static assert(false, "Unsupported platform");
}