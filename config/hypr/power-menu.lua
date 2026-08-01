--------------------------------
-- Lock and power menu
--------------------------------

hl.bind(
    "SUPER + L",
    hl.dsp.exec_cmd("$HOME/.local/bin/lock-screen"),
    {
        description = "Lock Screen",
    }
)

hl.bind(
    "SUPER + ESCAPE",
    hl.dsp.exec_cmd("$HOME/.local/bin/power-menu"),
    {
        description = "Power Menu",
    }
)

require("settings-panel")
