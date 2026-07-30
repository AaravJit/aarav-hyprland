--------------------------------
-- Aarav's final visual polish
--------------------------------

-- Small usability and geometry refinements.
hl.config({
    general = {
        resize_on_border = true,
    },

    decoration = {
        rounding = 12,
        rounding_power = 3.2,
    },
})

----------------------
-- Coherent animation
----------------------

hl.curve(
    "aaravEaseOut",
    {
        type = "bezier",
        points = {
            { 0.22, 1.00 },
            { 0.36, 1.00 },
        },
    }
)

hl.curve(
    "aaravClose",
    {
        type = "bezier",
        points = {
            { 0.40, 0.00 },
            { 1.00, 1.00 },
        },
    }
)

hl.curve(
    "aaravFade",
    {
        type = "bezier",
        points = {
            { 0.20, 0.00 },
            { 0.00, 1.00 },
        },
    }
)

hl.curve(
    "aaravSpring",
    {
        type = "spring",
        mass = 1,
        stiffness = 105,
        dampening = 21,
    }
)

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 3.8,
    bezier = "aaravEaseOut",
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3.6,
    spring = "aaravSpring",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3.2,
    spring = "aaravSpring",
    style = "popin 94%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 1.8,
    bezier = "aaravClose",
    style = "popin 96%",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 4.1,
    spring = "aaravSpring",
})

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 2.4,
    bezier = "aaravFade",
})

hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 2.2,
    bezier = "aaravFade",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 1.7,
    bezier = "aaravClose",
})

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 3.0,
    bezier = "aaravEaseOut",
    style = "fade",
})

hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 2.8,
    bezier = "aaravEaseOut",
    style = "fade",
})

hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 1.8,
    bezier = "aaravClose",
    style = "fade",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.5,
    bezier = "aaravEaseOut",
    style = "slidefade 12%",
})

-----------------------------
-- Smart single-window layout
-----------------------------

-- Remove gaps when a normal workspace contains exactly one tiled window.
hl.workspace_rule({
    workspace = "w[tv1]s[false]",
    gaps_in = 0,
    gaps_out = 0,
})

-- Also cover workspaces occupied by one fullscreen-state window.
hl.workspace_rule({
    workspace = "f[1]s[false]",
    gaps_in = 0,
    gaps_out = 0,
})

hl.window_rule({
    name = "aarav-single-window-clean",
    match = {
        float = false,
        workspace = "w[tv1]s[false]",
    },

    border_size = 0,
    rounding = 0,
})

hl.window_rule({
    name = "aarav-fullscreen-workspace-clean",
    match = {
        float = false,
        workspace = "f[1]s[false]",
    },

    border_size = 0,
    rounding = 0,
})

----------------------
-- Safe reload shortcut
----------------------

hl.bind(
    "SUPER + CTRL + R",
    hl.dsp.exec_cmd(
        "$HOME/.local/bin/hypr-safe-reload"
    ),
    {
        description = "Safely reload Hyprland",
    }
)
