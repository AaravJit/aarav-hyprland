--------------------------------
-- Aarav settings control center
--------------------------------

local settingsManager =
    "$HOME/.config/quickshell/overview/settings-panel/settings.py"

hl.bind(
    "SUPER + comma",
    hl.dsp.exec_cmd("python " .. settingsManager .. " open"),
    {
        description = "Open Aarav Settings",
    }
)

hl.window_rule({
    name = "aarav-settings-panel",

    match = {
        class = "^aarav-settings$",
    },

    float = true,
    center = true,
    size = { 1120, 760 },
    persistent_size = true,
    dim_around = true,
    rounding = 22,
    opacity = "1.0 override 1.0 override 1.0 override",
})

local generatedSettings =
    os.getenv("HOME")
    .. "/.config/hypr/generated/user-settings.lua"

local generatedSettingsFile = io.open(generatedSettings, "r")

if generatedSettingsFile then
    generatedSettingsFile:close()
    dofile(generatedSettings)
end
