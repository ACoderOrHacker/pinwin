set_xmakever("2.8.7")
set_version("0.1.0")

set_description("Pin a window to the top")

includes("@builtin/xpack")

add_rules("mode.debug", "mode.release")

add_includedirs("src")

if is_os("windows") then
	target("resources")
		set_kind("shared")

		add_files("res/pin.rc")
		add_shflags("/NOENTRY", { toolchain = "msvc" })
	target_end()
end

target("pinwin")
    set_kind("binary")

    add_files("src/**.d")
target_end()

xpack("pinwin")
    set_description("Pin a window to the top")
    set_author("ACoderOrHacker")
    set_license("MIT")
    set_licensefile("LICENSE")
    set_title("Pinwin")
	
	set_iconfile("res/pin.ico")

    set_formats("zip", "targz", "nsis")

    set_basename("pinwin-$(version)-$(plat)-$(arch)")

    add_installfiles("LICENSE")
    add_installfiles("README.md")

    add_sourcefiles("src/(**.d)")
    add_sourcefiles(".github/(**.yml)")

    add_targets("pinwin")
    add_targets("resources")
	
	add_components("autostartup")
xpack_end()

xpack_component("autostartup")
    set_default(true)
    set_title("Auto startup")
    set_description("Automatically start pinwin after powering on.")
    on_installcmd(function (component, batchcmds)
        batchcmds:rawcmd("nsis", [[
   ${If} $NoAdmin == "false"
    WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "PinwinStartup" "$INSTDIR\pinwin.exe"
   ${EndIf}]])
     end)
	
	on_uninstallcmd(function (component, batchcmds)
		batchcmds:rawcmd("nsis", [[
   ${If} $NoAdmin == "false"
    DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "PinwinStartup"
   ${EndIf}]])
	end)
xpack_component_end()