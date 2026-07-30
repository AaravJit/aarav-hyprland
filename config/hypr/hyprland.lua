-- Aarav's Hyprland configuration
-- Stage 1: minimal, bootable foundation

-------------------
-- Applications
-------------------

local terminal = "uwsm app -- kitty"
local launcher = "uwsm app -- fuzzel"
local fileManager = "uwsm app -- dolphin"

-------------------
-- Monitor
-------------------

-- Safe fallback. Once inside Hyprland, we'll replace this with the
-- exact connector and __MONITOR_MODE__ monitor rule.
hl.monitor({
    output = "__MONITOR__",
    mode = "__MONITOR_MODE__",
    position = "0x0",
    scale = 1,
    vrr = 0,
})

-------------------
-- Base behavior
-------------------

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,

        col = {
            active_border = "rgba(ffffffff)",
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,

        active_opacity = 0.97,
        inactive_opacity = 0.92,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = 0x88000000,
        },

        blur = {
            enabled = true,
            size = 7,
            passes = 3,
            vibrancy = 0.12,
        },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout = "us",
        follow_mouse = 1,

        -- Constant mouse movement with no acceleration curve
        accel_profile = "flat",
        sensitivity = -0.40,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        disable_hyprland_logo = true,
        force_default_wallpaper = 0,
    },
})

-------------------
-- Keybindings
-------------------

local mainMod = "SUPER"

-- Core applications
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-- Window controls
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({
    action = "toggle",
}))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.layout("togglesplit"))

-- Exit Hyprland
hl.bind(
    mainMod .. " + SHIFT + ESCAPE",
    hl.dsp.exec_cmd("hyprshutdown")
)

-- Move focus
hl.bind(mainMod .. " + left", hl.dsp.focus({
    direction = "left",
}))
hl.bind(mainMod .. " + right", hl.dsp.focus({
    direction = "right",
}))
hl.bind(mainMod .. " + up", hl.dsp.focus({
    direction = "up",
}))
hl.bind(mainMod .. " + down", hl.dsp.focus({
    direction = "down",
}))

-- Workspaces 1 through 10
for i = 1, 5 do
    local key = i % 10

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i })
    )
end

-- Scroll through workspaces
hl.bind(
    mainMod .. " + mouse_down",
    hl.dsp.focus({ workspace = "e+1" })
)

hl.bind(
    mainMod .. " + mouse_up",
    hl.dsp.focus({ workspace = "e-1" })
)

-- Hold Super and drag with left/right mouse
hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

-----------------------------
-- Stage 2: daily desktop controls
-----------------------------

-- Fullscreen removes the bar and gaps.
hl.bind(
    mainMod .. " + F",
    hl.dsp.window.fullscreen({
        mode = "fullscreen",
        action = "toggle",
    })
)

-- Maximize preserves the bar and usable desktop area.
hl.bind(
    mainMod .. " + SHIFT + F",
    hl.dsp.window.fullscreen({
        mode = "maximized",
        action = "toggle",
    })
)

-- Move tiled windows with Super + Shift + arrow.
hl.bind(
    mainMod .. " + SHIFT + left",
    hl.dsp.window.move({ direction = "left" })
)

hl.bind(
    mainMod .. " + SHIFT + right",
    hl.dsp.window.move({ direction = "right" })
)

hl.bind(
    mainMod .. " + SHIFT + up",
    hl.dsp.window.move({ direction = "up" })
)

hl.bind(
    mainMod .. " + SHIFT + down",
    hl.dsp.window.move({ direction = "down" })
)

-- Scratchpad workspace.
hl.bind(
    mainMod .. " + R",
    hl.dsp.workspace.toggle_special("scratch")
)

hl.bind(
    mainMod .. " + SHIFT + R",
    hl.dsp.window.move({
        workspace = "special:scratch",
    })
)

-- Notification center.
hl.bind(
    mainMod .. " + Z",
    hl.dsp.exec_cmd("swaync-client -t -sw")
)

-- Restart Waybar after editing its files.
hl.bind(
    mainMod .. " + SHIFT + B",
    hl.dsp.exec_cmd(
        "systemctl --user restart waybar.service"
    )
)

-------------------
-- Audio controls
-------------------

hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "swayosd-client --monitor __MONITOR__ --output-volume +5 --max-volume 100"
    ),
    {
        locked = true,
        repeating = true,
    }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "swayosd-client --monitor __MONITOR__ --output-volume -5 --max-volume 100"
    ),
    {
        locked = true,
        repeating = true,
    }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd(
        "swayosd-client --monitor __MONITOR__ --output-volume mute-toggle"
    ),
    {
        locked = true,
    }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd(
        "swayosd-client --monitor __MONITOR__ --input-volume mute-toggle"
    ),
    {
        locked = true,
    }
)

hl.bind(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    {
        locked = true,
    }
)

hl.bind(
    "XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    {
        locked = true,
    }
)

hl.bind(
    "XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    {
        locked = true,
    }
)

hl.bind(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    {
        locked = true,
    }
)


-----------------------------------------------
-- Stage 3: visual motion and desktop utilities
-----------------------------------------------

-- Fast, controlled animations rather than excessive bouncing.
hl.curve(
    "desktopEase",
    {
        type = "bezier",
        points = {
            { 0.22, 1.0 },
            { 0.36, 1.0 },
        },
    }
)

hl.curve(
    "desktopQuick",
    {
        type = "bezier",
        points = {
            { 0.15, 0.0 },
            { 0.10, 1.0 },
        },
    }
)

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 5,
    bezier = "desktopEase",
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "desktopEase",
    style = "popin 92%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "desktopQuick",
    style = "popin 92%",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4,
    bezier = "desktopEase",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3,
    bezier = "desktopQuick",
})

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4,
    bezier = "desktopEase",
    style = "fade",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "desktopEase",
    style = "slidefade 15%",
})

-- Blur transparent layer-shell applications.
hl.layer_rule({
    match = {
        namespace = "waybar",
    },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.18,
})

hl.layer_rule({
    match = {
        namespace = "launcher",
    },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.12,
})

-------------------
-- Clipboard
-------------------

hl.bind(
    mainMod .. " + V",
    hl.dsp.exec_cmd("$HOME/.local/bin/clipboard-menu")
)

-------------------
-- Screenshots
-------------------

-- Select a region, then annotate it.
hl.bind(
    mainMod .. " + X",
    hl.dsp.exec_cmd(
        "$HOME/.local/bin/screenshot-region-edit"
    )
)

-- Select a region and copy it directly.
hl.bind(
    mainMod .. " + SHIFT + X",
    hl.dsp.exec_cmd(
        "$HOME/.local/bin/screenshot-region-copy"
    )
)

-- Save the entire monitor.
hl.bind(
    mainMod .. " + CTRL + X",
    hl.dsp.exec_cmd(
        "$HOME/.local/bin/screenshot-output"
    )
)

-------------------
-- Utility launchers
-------------------

hl.bind(
    mainMod .. " + A",
    hl.dsp.exec_cmd("uwsm app -- pavucontrol")
)

hl.bind(
    mainMod .. " + SHIFT + C",
    hl.dsp.exec_cmd(
        "hyprpicker -a && notify-send 'Color copied' 'Hex value copied to clipboard.'"
    )
)


---------------------------------
-- Stage 4: SwayNC layer effects
---------------------------------

hl.layer_rule({
    match = {
        namespace = "swaync-control-center",
    },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
})

hl.layer_rule({
    match = {
        namespace = "swaync-notification-window",
    },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
})


------------------------------------------
-- Stage 5: session and appearance controls
------------------------------------------

-- Lock the session.
hl.bind(
    mainMod .. " + ESCAPE",
    hl.dsp.exec_cmd("$HOME/.local/bin/lock-screen")
)

-- Select and apply a wallpaper.
hl.bind(
    mainMod .. " + W",
    hl.dsp.exec_cmd("$HOME/.local/bin/set-wallpaper")
)


----------------------------------------
-- Stage 7: left-hand application binds
----------------------------------------

local appLauncher = "$HOME/.local/bin/launch-app"

hl.bind(
    mainMod .. " + B",
    hl.dsp.exec_cmd(
        "uwsm app -- " .. appLauncher .. " zen"
    ),
    {
        description = "Open Zen Browser",
    }
)

hl.bind(
    mainMod .. " + S",
    hl.dsp.exec_cmd(
        "uwsm app -- " .. appLauncher .. " spotify"
    ),
    {
        description = "Open Spotify",
    }
)

hl.bind(
    mainMod .. " + D",
    hl.dsp.exec_cmd(
        "uwsm app -- " .. appLauncher .. " discord"
    ),
    {
        description = "Open Discord",
    }
)

hl.bind(
    mainMod .. " + G",
    hl.dsp.exec_cmd(
        "uwsm app -- " .. appLauncher .. " steam"
    ),
    {
        description = "Open Steam",
    }
)

hl.bind(
    mainMod .. " + SHIFT + G",
    hl.dsp.exec_cmd(
        "uwsm app -- " .. appLauncher .. " heroic"
    ),
    {
        description = "Open Heroic Games Launcher",
    }
)


-----------------------------
-- Dynamic Matugen theme
-----------------------------

local matugenTheme =
    os.getenv("HOME") .. "/.config/hypr/matugen.lua"

local matugenFile = io.open(matugenTheme, "r")

if matugenFile then
    matugenFile:close()
    dofile(matugenTheme)
end


-----------------------------
-- Aarav's application rules
-----------------------------

local applicationRules =
    os.getenv("HOME") .. "/.config/hypr/app-rules.lua"

local applicationRulesFile = io.open(applicationRules, "r")

if applicationRulesFile then
    applicationRulesFile:close()
    dofile(applicationRules)
end


--------------------------------
-- Stage 10: SwayOSD glass layer
--------------------------------

hl.layer_rule({
    match = {
        namespace = "swayosd",
    },

    blur = true,
    blur_popups = true,
    ignore_alpha = 0.10,
})


-----------------------------

--------------------------------
-- Stage 14: Final Polish Loader
--------------------------------

local finalPolishPath =
    os.getenv("HOME") .. "/.config/hypr/final-polish.lua"

local finalPolishFile =
    io.open(finalPolishPath, "r")

if finalPolishFile then
    finalPolishFile:close()
    dofile(finalPolishPath)
end


-- Stage 12: Gaming Mode
-----------------------------

local gamingModeState =
    (os.getenv("XDG_RUNTIME_DIR") or "/tmp")
    .. "/aarav-gamemode"

local gamingModeFile = io.open(gamingModeState, "r")

if gamingModeFile then
    gamingModeFile:close()

    hl.config({
        general = {
            gaps_in = 0,
            gaps_out = 0,
            border_size = 0,
        },

        animations = {
            enabled = false,
        },

        decoration = {
            rounding = 0,

            shadow = {
                enabled = false,
            },

            blur = {
                enabled = false,
            },
        },
    })
end

hl.bind(
    mainMod .. " + CTRL + G",
    hl.dsp.exec_cmd(
        "$HOME/.local/bin/gaming-mode toggle"
    ),
    {
        description = "Toggle Gaming Mode",
    }
)


------------------------------------------
-- Stage 13: Quickshell Workspace Overview
------------------------------------------

hl.layer_rule({
    name = "quickshell-overview-glass",

    match = {
        namespace = "^quickshell:overview-blur$",
    },

    blur = true,
    blur_popups = true,
    ignore_alpha = 0.20,
})

hl.bind(
    mainMod .. " + TAB",
    hl.dsp.exec_cmd(
        "qs ipc -c overview call overview toggle"
    ),
    {
        description = "Workspace Overview",
    }
)

--------------------------------
-- Generated hardware overrides
--------------------------------

require("generated.hardware")
