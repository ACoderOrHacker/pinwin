module pinwin.pinwin;

version (Windows)
{
    import core.sys.windows.windows;
    import core.sys.windows.winuser : SetWindowPos;

    nothrow void pinWindow(HWND hwnd) {
        SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
        ShowWindow(hwnd, SW_SHOW);
    }

    nothrow void unpinWindow(HWND hwnd) {
        SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
        ShowWindow(hwnd, SW_SHOW);
    }
}