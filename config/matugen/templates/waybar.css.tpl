* {
    border: none;
    border-radius: 0;

    font-family:
        "Noto Sans",
        "Symbols Nerd Font Mono",
        sans-serif;

    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: transparent;
    color: {{colors.on_surface.default.hex}};
}

tooltip {
    background: {{colors.surface_container_high.default.hex}}F2;
    border: 1px solid {{colors.outline_variant.default.hex}}80;
    border-radius: 12px;
}

tooltip label {
    color: {{colors.on_surface.default.hex}};
    padding: 7px;
}

#custom-launcher,
#workspaces,
#window,
#idle_inhibitor,
#custom-notification,
#pulseaudio,
#network,
#cpu,
#memory,
#tray,
#clock {
    background: {{colors.surface_container.default.hex}}C7;

    border: 1px solid {{colors.outline_variant.default.hex}}55;
    border-radius: 13px;

    color: {{colors.on_surface.default.hex}};

    margin: 0 2px;
    padding: 0 13px;

    box-shadow: 0 3px 10px {{colors.shadow.default.hex}}73;
}

#custom-launcher {
    color: {{colors.primary.default.hex}};

    font-family:
        "Symbols Nerd Font Mono",
        sans-serif;

    font-size: 20px;
    padding: 0 16px;
}

#custom-launcher:hover {
    background: {{colors.surface_container_high.default.hex}}EB;
    color: {{colors.on_surface.default.hex}};
}

#workspaces {
    padding: 0 5px;
}

#workspaces button {
    background: transparent;
    color: {{colors.on_surface_variant.default.hex}};

    border-radius: 9px;

    min-width: 25px;
    margin: 4px 1px;
    padding: 0 8px;

    font-weight: 600;
}

#workspaces button:hover {
    background: {{colors.surface_container_highest.default.hex}}A6;
    color: {{colors.on_surface.default.hex}};
}

#workspaces button.active {
    background: {{colors.primary_container.default.hex}}C2;
    color: {{colors.on_primary_container.default.hex}};
}

#workspaces button.special {
    color: {{colors.tertiary.default.hex}};
}

#workspaces button.urgent {
    background: {{colors.error_container.default.hex}}E8;
    color: {{colors.on_error_container.default.hex}};
}

#window {
    min-width: 360px;
    font-weight: 500;
}

window#waybar.empty #window {
    background: transparent;
    border-color: transparent;
    box-shadow: none;
}

#idle_inhibitor,
#custom-notification,
#network {
    font-family:
        "Symbols Nerd Font Mono",
        "Noto Sans",
        sans-serif;

    font-size: 17px;
}

#idle_inhibitor.activated {
    color: {{colors.primary.default.hex}};
}

#custom-notification.notification {
    color: {{colors.tertiary.default.hex}};
}

#pulseaudio.muted,
#network.disconnected {
    color: {{colors.error.default.hex}};
}

#pulseaudio:hover,
#network:hover,
#idle_inhibitor:hover,
#custom-notification:hover,
#clock:hover {
    background: {{colors.surface_container_high.default.hex}}EB;
}

#cpu,
#memory {
    color: {{colors.on_surface_variant.default.hex}};
}

#clock {
    color: {{colors.on_surface.default.hex}};
    font-weight: 600;
}

#tray {
    padding: 0 11px;
}
