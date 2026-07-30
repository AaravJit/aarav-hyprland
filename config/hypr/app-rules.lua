-- Aarav's application rules
-- Loaded by hyprland.lua

--------------------------------
-- Focus and modal presentation
--------------------------------

hl.config({
    decoration = {
        -- Subtle focus separation without making inactive apps unreadable.
        dim_inactive = true,
        dim_strength = 0.08,

        -- Stronger dimming behind modal dialogs and the scratchpad.
        dim_modal = true,
        dim_around = 0.42,
        dim_special = 0.20,
    },
})

-------------------
-- Zen Browser
-------------------

hl.window_rule({
    match = {
        class = "^zen$",
    },

    opacity = "0.98 override 0.94 override 1.0 override",
    rounding = 12,
})

-------------------
-- Spotify
-------------------

hl.window_rule({
    match = {
        class = "^Spotify$",
    },

    opacity = "0.96 override 0.92 override 1.0 override",
    rounding = 12,
})

-------------------
-- Discord
-------------------

hl.window_rule({
    match = {
        class = "^discord$",
    },

    opacity = "0.97 override 0.93 override 1.0 override",
    rounding = 12,
})

-------------------
-- Steam
-------------------

hl.window_rule({
    match = {
        class = "^steam$",
    },

    opacity = "1.0 override 1.0 override 1.0 override",
    no_blur = true,
    rounding = 10,
})

-------------------
-- Heroic
-------------------

hl.window_rule({
    match = {
        class = "^com%.heroicgameslauncher%.hgl$",
    },

    opacity = "1.0 override 1.0 override 1.0 override",
    no_blur = true,
    rounding = 10,
})

-------------------
-- Picture-in-picture
-------------------

hl.window_rule({
    match = {
        class = "^zen$",
        title = ".*Picture.in.Picture.*",
    },

    float = true,
    pin = true,

    size = { 720, 405 },
    move = {
        "monitor_w-window_w-24",
        "monitor_h-window_h-72",
    },

    keep_aspect_ratio = true,

    opacity = "1.0 override 1.0 override 1.0 override",
    rounding = 16,
    no_blur = true,
})

-------------------
-- Pavucontrol
-------------------

hl.window_rule({
    match = {
        class = "^(pavucontrol|org%.pulseaudio%.pavucontrol)$",
    },

    float = true,
    center = true,
    size = { 980, 680 },

    persistent_size = true,
    dim_around = true,

    opacity = "0.98 override 0.96 override 1.0 override",
    rounding = 16,
})

-------------------
-- Modal dialogs
-------------------

hl.window_rule({
    match = {
        modal = true,
    },

    float = true,
    center = true,

    dim_around = true,
    rounding = 16,

    opacity = "0.98 override 0.98 override 1.0 override",
})

-------------------
-- Common file dialogs
-------------------

hl.window_rule({
    match = {
        title = "^(Open File|Save File|Choose Files|Select a File|Save As)$",
    },

    float = true,
    center = true,
    size = { 1100, 760 },

    persistent_size = true,
    dim_around = true,
    rounding = 16,

    opacity = "0.98 override 0.98 override 1.0 override",
})

-------------------
-- Recognized game content
-------------------

hl.window_rule({
    match = {
        content = "game",
    },

    opacity = "1.0 override 1.0 override 1.0 override",

    no_blur = true,
    no_anim = true,
    no_shadow = true,

    rounding = 0,
    border_size = 0,

    idle_inhibit = "fullscreen",
})

-------------------
-- Every fullscreen window
-------------------

-- This is intentionally last. Fullscreen video and games must remain
-- completely opaque regardless of their normal application styling.
hl.window_rule({
    match = {
        fullscreen = true,
    },

    opacity = "1.0 override 1.0 override 1.0 override",

    no_blur = true,
    rounding = 0,
    border_size = 0,
})
