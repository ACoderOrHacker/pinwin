set_xmakever("2.8.7")

set_description("Pin a window to the top")

includes("@builtin/xpack")

add_rules("mode.debug", "mode.release")

add_includedirs("src")

target("resources")
    set_kind("shared")

    add_files("res/pin.rc")
    add_shflags("/NOENTRY", { toolchain = "msvc" })
target_end()

target("pinwin")
    set_kind("binary")

    add_files("src/**.d")
target_end()

xpack("shit")
    set_description("Pin a window to the top")
    set_author("ACoderOrHacker")
    set_license("MIT")
    set_licensefile("LICENSE")
    set_title("Pinwin")

    set_formats("zip", "targz", "nsis")

    set_basename("shit-$(version)-$(plat)-$(arch)")

    add_installfiles("LICENSE")
    add_installfiles("README.md")

    add_sourcefiles("src/(**.d)")
    add_sourcefiles(".github/(**.yml)")

    add_targets("pinwin")
xpack_end()