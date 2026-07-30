* {
    font-family:
        "Noto Sans",
        "Symbols Nerd Font Mono",
        sans-serif;

    font-size: 14px;
}

.blank-window,
.floating-notifications {
    background: transparent;
}

.control-center {
    background: {{colors.surface_container.default.hex}}DB;
    color: {{colors.on_surface.default.hex}};

    border: 1px solid {{colors.outline_variant.default.hex}}73;
    border-radius: 18px;

    padding: 10px;

    box-shadow: 0 10px 32px {{colors.shadow.default.hex}}8C;
}

.control-center-list,
.notification-row,
.notification-background,
.notification-content {
    background: transparent;
}

.control-center-list-placeholder {
    color: {{colors.on_surface_variant.default.hex}};
}

.notification-background {
    padding: 5px;
}

.notification {
    background: {{colors.surface_container_high.default.hex}}ED;

    border: 1px solid {{colors.outline_variant.default.hex}}59;
    border-radius: 15px;

    box-shadow: 0 5px 18px {{colors.shadow.default.hex}}66;
}

.notification:hover {
    background: {{colors.surface_container_highest.default.hex}}F2;
}

.notification-content {
    padding: 10px;
}

.notification-default-action,
.notification-action {
    background: transparent;
    border: none;
    border-radius: 14px;

    color: {{colors.on_surface.default.hex}};
}

.notification-default-action:hover,
.notification-action:hover {
    background: {{colors.primary_container.default.hex}}4D;
}

.summary {
    color: {{colors.on_surface.default.hex}};
    font-size: 15px;
    font-weight: 700;
}

.body {
    color: {{colors.on_surface_variant.default.hex}};
    font-size: 13px;
}

.time {
    color: {{colors.outline.default.hex}};
    font-size: 12px;
    margin-right: 28px;
}

.close-button {
    background: {{colors.surface_container_highest.default.hex}}B3;
    color: {{colors.on_surface.default.hex}};

    border: none;
    border-radius: 999px;

    min-width: 24px;
    min-height: 24px;

    box-shadow: none;
}

.close-button:hover {
    background: {{colors.error_container.default.hex}};
    color: {{colors.on_error_container.default.hex}};
}

.notification.critical {
    border-color: {{colors.error.default.hex}};
}

.widget-title,
.widget-dnd,
.widget-mpris,
.widget-volume {
    background: {{colors.surface_container_high.default.hex}}D1;

    border: 1px solid {{colors.outline_variant.default.hex}}59;
    border-radius: 15px;

    color: {{colors.on_surface.default.hex}};

    margin: 5px;
    padding: 11px;
}

.widget-title > label {
    color: {{colors.on_surface.default.hex}};
    font-size: 18px;
    font-weight: 700;
}

.widget-title > button {
    background: {{colors.surface_container_highest.default.hex}}A6;
    color: {{colors.on_surface_variant.default.hex}};

    border: none;
    border-radius: 10px;

    padding: 7px 12px;
}

.widget-title > button:hover {
    background: {{colors.error_container.default.hex}};
    color: {{colors.on_error_container.default.hex}};
}

.widget-dnd > switch {
    background: {{colors.surface_container_highest.default.hex}};
    border: none;
    border-radius: 999px;
}

.widget-dnd > switch:checked {
    background: {{colors.primary.default.hex}};
}

.widget-dnd > switch slider {
    background: {{colors.on_primary.default.hex}};
    border-radius: 999px;
}

.widget-mpris {
    padding: 8px;
}

.widget-mpris-player {
    background: {{colors.surface_container_low.default.hex}}C7;
    border-radius: 13px;
    padding: 9px;
}

.widget-volume trough {
    background: {{colors.surface_container_highest.default.hex}};
    border-radius: 999px;
    min-height: 7px;
}

.widget-volume highlight {
    background: {{colors.primary.default.hex}};
    border-radius: 999px;
}

.widget-volume slider {
    background: {{colors.on_primary.default.hex}};
    border-radius: 999px;

    min-width: 14px;
    min-height: 14px;
}


/* Aarav's wallpaper-colored quick settings */

.widget-buttons-grid {
    background: transparent;
    margin: 4px;
}

.widget-buttons-grid > flowbox {
    background: transparent;
    padding: 0;
}

.widget-buttons-grid > flowbox > flowboxchild {
    background: transparent;
    padding: 4px;
}

.widget-buttons-grid > flowbox > flowboxchild > button {
    background: {{colors.surface_container_high.default.hex}};
    color: {{colors.on_surface.default.hex}};

    border: 1px solid {{colors.outline_variant.default.hex}};
    border-radius: 14px;

    min-width: 112px;
    min-height: 50px;

    padding: 10px 13px;

    font-family:
        "Noto Sans",
        "Symbols Nerd Font Mono",
        sans-serif;

    font-size: 13px;
    font-weight: 700;
}

.widget-buttons-grid > flowbox > flowboxchild > button:hover {
    background: {{colors.surface_container_highest.default.hex}};
    border-color: {{colors.primary.default.hex}};
}

.widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked {
    background: {{colors.primary_container.default.hex}};
    color: {{colors.on_primary_container.default.hex}};

    border-color: {{colors.primary.default.hex}};
}

.widget-buttons-grid > flowbox > flowboxchild > button.toggle:checked:hover {
    background: {{colors.primary.default.hex}};
    color: {{colors.on_primary.default.hex}};
}
