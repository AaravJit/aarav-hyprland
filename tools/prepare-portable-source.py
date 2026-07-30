#!/usr/bin/env python3

from __future__ import annotations

import copy
import json
import os
import re
import shutil
import stat
import subprocess
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
IMPORT_HOME = REPO / ".local-import/home"

CONFIG = REPO / "config"
SCRIPTS = REPO / "scripts"
SYSTEMD = REPO / "systemd/user"
GPU_PROFILES = REPO / "profiles/gpu"

CURRENT_HOME = str(Path.home())
CURRENT_WALLPAPER_DIR = str(
    Path.home() / "Documents/Wallpapers"
)

TOKEN_HOME = "__HOME__"
TOKEN_MONITOR = "__MONITOR__"
TOKEN_MONITOR_MODE = "__MONITOR_MODE__"
TOKEN_WALLPAPER_DIR = "__WALLPAPER_DIR__"


def reset_directory(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path)

    path.mkdir(parents=True, exist_ok=True)


def portable_text(text: str) -> str:
    replacements = [
        (
            CURRENT_WALLPAPER_DIR,
            TOKEN_WALLPAPER_DIR,
        ),
        (
            "$HOME/Documents/Wallpapers",
            TOKEN_WALLPAPER_DIR,
        ),
        (
            CURRENT_HOME,
            TOKEN_HOME,
        ),
        (
            "/home/aarav",
            TOKEN_HOME,
        ),
        (
            "3440x1440@144",
            TOKEN_MONITOR_MODE,
        ),
        (
            "DP-1",
            TOKEN_MONITOR,
        ),
    ]

    for old, new in replacements:
        text = text.replace(old, new)

    return text


def copy_text(
    source: Path,
    destination: Path,
    transform=None,
) -> None:
    if not source.is_file():
        return

    text = source.read_text(errors="replace")
    text = portable_text(text)

    if transform:
        text = transform(text)

    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(text)

    source_mode = source.stat().st_mode

    if source_mode & stat.S_IXUSR:
        destination.chmod(0o755)


def copy_tree(
    source: Path,
    destination: Path,
) -> None:
    if not source.is_dir():
        return

    ignored_patterns = (
        ".git",
        "__pycache__",
        "*.log",
        "*.pid",
        "*.lock",
        "*.before-*",
        "*.baseline-*",
        "*.stage*",
        "*.working",
        "*.bak",
        "*~",
    )

    for item in source.rglob("*"):
        if not item.is_file():
            continue

        relative = item.relative_to(source)

        if any(
            relative.match(pattern)
            or item.name == pattern
            for pattern in ignored_patterns
        ):
            continue

        copy_text(
            item,
            destination / relative,
        )


def add_hardware_loader(text: str) -> str:
    marker = 'require("generated.hardware")'

    if marker not in text:
        text = (
            text.rstrip()
            + "\n\n"
            + "--------------------------------\n"
            + "-- Generated hardware overrides\n"
            + "--------------------------------\n\n"
            + marker
            + "\n"
        )

    return text


def transform_waybar(text: str) -> str:
    replacements = {
        '"custom/nvidia"': '"custom/gpu"',
        "waybar-nvidia": "gpu-status",
        "NVIDIA Monitor": "GPU Monitor",
        "watch -n 1 nvidia-smi": "nvtop",
    }

    for old, new in replacements.items():
        text = text.replace(old, new)

    return portable_text(text)


def replace_modules_right(
    text: str,
    modules: list[str],
) -> str:
    rendered = ",\n".join(
        f'        "{module}"'
        for module in modules
    )

    replacement = (
        '"modules-right": [\n'
        f"{rendered}\n"
        "    ]"
    )

    pattern = re.compile(
        r'"modules-right"\s*:\s*\[.*?\]',
        flags=re.DOTALL,
    )

    updated, count = pattern.subn(
        replacement,
        text,
        count=1,
    )

    if count != 1:
        raise RuntimeError(
            "Could not replace Waybar modules-right."
        )

    return updated


LAPTOP_MODULES = r'''
    "backlight": {
        "format": "󰃠  {percent}%",
        "tooltip-format": "Display brightness: {percent}%",
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
    },

    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },

        "format": "{icon}  {capacity}%",
        "format-charging": "󰂄  {capacity}%",
        "format-plugged": "󰚥  {capacity}%",

        "format-icons": [
            "󰁺",
            "󰁻",
            "󰁼",
            "󰁽",
            "󰁾",
            "󰁿",
            "󰂀",
            "󰂁",
            "󰂂",
            "󰁹"
        ],

        "tooltip-format": "{capacity}%\n{timeTo}"
    },

'''


def add_laptop_module_definitions(
    text: str,
) -> str:
    if '"battery": {' in text:
        return text

    anchors = (
        '    "cpu": {',
        '    "clock": {',
    )

    for anchor in anchors:
        if anchor in text:
            return text.replace(
                anchor,
                LAPTOP_MODULES + anchor,
                1,
            )

    raise RuntimeError(
        "Could not find a Waybar module insertion point."
    )


def create_laptop_waybar(
    desktop_text: str,
    gaming: bool,
) -> str:
    if gaming:
        modules = [
            "custom/gpu",
            "battery",
            "pulseaudio",
            "custom/notification",
            "clock",
        ]
    else:
        modules = [
            "privacy",
            "custom/gpu",
            "battery",
            "backlight",
            "idle_inhibitor",
            "custom/notification",
            "pulseaudio",
            "network",
            "clock",
        ]

    text = replace_modules_right(
        desktop_text,
        modules,
    )

    text = add_laptop_module_definitions(text)

    text = text.replace(
        '"height": 42',
        '"height": 38',
        1,
    )

    text = text.replace(
        '"margin-top": 10',
        '"margin-top": 7',
        1,
    )

    text = text.replace(
        '"margin-left": 12',
        '"margin-left": 8',
        1,
    )

    text = text.replace(
        '"margin-right": 12',
        '"margin-right": 8',
        1,
    )

    return text


def transform_waybar_css(text: str) -> str:
    text = portable_text(text)
    text = text.replace(
        "#custom-nvidia",
        "#custom-gpu",
    )
    text = text.replace(
        "NVIDIA HUD",
        "Cross-vendor GPU HUD",
    )

    if '@import "profile.css";' not in text:
        lines = text.splitlines()

        insert_at = 0

        for index, line in enumerate(lines):
            if line.strip().startswith("@import"):
                insert_at = index + 1

        lines.insert(
            insert_at,
            '@import "profile.css";',
        )

        text = "\n".join(lines) + "\n"

    capsule_anchor = "#network,\n"

    if (
        "#backlight," not in text
        and capsule_anchor in text
    ):
        text = text.replace(
            capsule_anchor,
            (
                "#network,\n"
                "#backlight,\n"
                "#battery,\n"
            ),
            1,
        )

    text += r'''

/* Laptop-capable modules */

#battery,
#backlight {
    color: @on_surface_variant;
}

#battery.charging,
#battery.plugged {
    color: @tertiary;
}

#battery.warning {
    color: @primary;
}

#battery.critical {
    background-color: alpha(@error_container, 0.90);
    border-color: @error;
    color: @on_error_container;
}
'''

    return text


def filter_common_uwsm(text: str) -> str:
    blocked = re.compile(
        r"GBM_BACKEND|"
        r"__GLX_VENDOR_LIBRARY_NAME|"
        r"LIBVA_DRIVER_NAME|"
        r"__GL_|"
        r"\bNVIDIA\b",
        flags=re.IGNORECASE,
    )

    lines = [
        line
        for line in portable_text(text).splitlines()
        if not blocked.search(line)
    ]

    while lines and not lines[-1].strip():
        lines.pop()

    return "\n".join(lines) + "\n"


def collect_script_names() -> set[str]:
    names = {
        "gaming-mode",
        "hypr-health",
        "hypr-restore",
        "hypr-safe-reload",
        "hypr-snapshot",
        "launch-app",
        "lock-screen",
        "night-light",
        "power-menu",
        "set-wallpaper",
        "swaync-toggle",
        "waybar-center-hud",
        "waybar-launch",
    }

    scan_roots = [
        IMPORT_HOME / ".config/hypr",
        IMPORT_HOME / ".config/waybar",
        IMPORT_HOME / ".config/swaync",
        IMPORT_HOME / ".config/systemd/user",
    ]

    pattern = re.compile(
        r"(?:"
        r"\$HOME|"
        r"\$\{HOME\}|"
        r"%h|"
        r"/home/[A-Za-z0-9._-]+"
        r")"
        r"/\.local/bin/"
        r"([A-Za-z0-9._+-]+)"
    )

    for root in scan_roots:
        if not root.exists():
            continue

        for path in root.rglob("*"):
            if not path.is_file():
                continue

            try:
                text = path.read_text(
                    errors="replace"
                )
            except OSError:
                continue

            names.update(pattern.findall(text))

    names.discard("waybar-nvidia")

    return names


def transform_script(
    name: str,
    text: str,
) -> str:
    text = portable_text(text)

    if name == "hypr-health":
        text = re.sub(
            r"^\s*nvidia-smi\s*$",
            "    nvtop",
            text,
            flags=re.MULTILINE,
        )

    return text


def write_overview_source() -> None:
    target = CONFIG / "quickshell/overview"
    target.mkdir(parents=True, exist_ok=True)

    source = (
        IMPORT_HOME
        / ".config/quickshell/overview"
    )

    config_path = source / "config.json"

    if config_path.is_file():
        data = json.loads(
            config_path.read_text()
        )

        overview = data.setdefault(
            "overview",
            {},
        )

        overview["emptyWorkspaceWallpaper"] = (
            f"{TOKEN_HOME}/.config/hypr/"
            "wallpaper-current.jpg"
        )

        overview[
            "specialEmptyWorkspaceWallpaper"
        ] = (
            f"{TOKEN_HOME}/.config/hypr/"
            "wallpaper-current.jpg"
        )

        desktop = copy.deepcopy(data)
        laptop = copy.deepcopy(data)

        laptop_overview = laptop.setdefault(
            "overview",
            {},
        )

        laptop_overview["rows"] = 2
        laptop_overview["columns"] = 3
        laptop_overview[
            "specialWorkspaceColumns"
        ] = 3
        laptop_overview["scale"] = 0.20
        laptop_overview[
            "workspaceSpacing"
        ] = 8
        laptop_overview[
            "backgroundPadding"
        ] = 12

        (
            target
            / "config.desktop.json"
        ).write_text(
            json.dumps(
                desktop,
                indent=4,
            )
            + "\n"
        )

        (
            target
            / "config.laptop.json"
        ).write_text(
            json.dumps(
                laptop,
                indent=4,
            )
            + "\n"
        )

    appearance = (
        source
        / "common/Appearance.colors.qml"
    )

    if appearance.is_file():
        copy_text(
            appearance,
            target
            / "Appearance.colors.fallback.qml",
        )

    live_source = (
        Path.home()
        / ".config/quickshell/overview"
    )

    repository = (
        "https://github.com/"
        "Shanu-Kumawat/quickshell-overview.git"
    )
    commit = "UNKNOWN"

    if (live_source / ".git").exists():
        try:
            repository_result = subprocess.run(
                [
                    "git",
                    "-C",
                    str(live_source),
                    "remote",
                    "get-url",
                    "origin",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            if repository_result.returncode == 0:
                repository = (
                    repository_result.stdout.strip()
                    or repository
                )

            commit_result = subprocess.run(
                [
                    "git",
                    "-C",
                    str(live_source),
                    "rev-parse",
                    "HEAD",
                ],
                check=False,
                capture_output=True,
                text=True,
            )

            if commit_result.returncode == 0:
                commit = (
                    commit_result.stdout.strip()
                    or commit
                )
        except OSError:
            pass

    (target / "source.env").write_text(
        f'OVERVIEW_REPOSITORY="{repository}"\n'
        f'OVERVIEW_COMMIT="{commit}"\n'
    )


def main() -> None:
    if not IMPORT_HOME.is_dir():
        raise SystemExit(
            "Missing .local-import/home. "
            "Run tools/import-current.sh first."
        )

    for directory in (
        CONFIG / "hypr",
        CONFIG / "waybar",
        CONFIG / "swaync",
        CONFIG / "swayosd",
        CONFIG / "matugen",
        CONFIG / "quickshell",
        CONFIG / "fuzzel",
        CONFIG / "kitty",
        CONFIG / "uwsm",
        SYSTEMD,
        GPU_PROFILES,
    ):
        reset_directory(directory)

    hypr_source = (
        IMPORT_HOME / ".config/hypr"
    )

    hypr_files = {
        "hyprland.lua": add_hardware_loader,
        "app-rules.lua": None,
        "final-polish.lua": None,
        "hypridle.conf": None,
        "hyprlock.conf": None,
        "hyprpaper.conf": None,
    }

    for filename, transform in hypr_files.items():
        copy_text(
            hypr_source / filename,
            CONFIG / "hypr" / filename,
            transform=transform,
        )

    generated_fallbacks = {
        "matugen.lua": "matugen.fallback.lua",
        (
            "hyprlock-colors.conf"
        ): "hyprlock-colors.fallback.conf",
    }

    for source_name, target_name in (
        generated_fallbacks.items()
    ):
        copy_text(
            hypr_source / source_name,
            CONFIG / "hypr" / target_name,
        )

    waybar_source = (
        IMPORT_HOME / ".config/waybar"
    )

    desktop_config = transform_waybar(
        (
            waybar_source / "config.jsonc"
        ).read_text()
    )

    desktop_gaming = transform_waybar(
        (
            waybar_source
            / "config-gaming.jsonc"
        ).read_text()
    )

    (
        CONFIG
        / "waybar/config.desktop.jsonc"
    ).write_text(desktop_config)

    (
        CONFIG
        / "waybar/config-gaming.desktop.jsonc"
    ).write_text(desktop_gaming)

    (
        CONFIG
        / "waybar/config.laptop.jsonc"
    ).write_text(
        create_laptop_waybar(
            desktop_config,
            gaming=False,
        )
    )

    (
        CONFIG
        / "waybar/config-gaming.laptop.jsonc"
    ).write_text(
        create_laptop_waybar(
            desktop_gaming,
            gaming=True,
        )
    )

    style = transform_waybar_css(
        (
            waybar_source / "style.css"
        ).read_text()
    )

    (
        CONFIG / "waybar/style.css"
    ).write_text(style)

    (
        CONFIG
        / "waybar/profile.desktop.css"
    ).write_text(
        "/* Desktop profile uses base geometry. */\n"
    )

    (
        CONFIG
        / "waybar/profile.laptop.css"
    ).write_text(
        r'''/* Compact laptop geometry */

* {
    font-size: 13px;
}

#custom-center-hud {
    min-width: 245px;
    padding-left: 12px;
    padding-right: 12px;
}

#custom-launcher,
#custom-gpu,
#idle_inhibitor,
#custom-notification,
#pulseaudio,
#network,
#battery,
#backlight,
#clock {
    padding-left: 9px;
    padding-right: 9px;
}

#cpu,
#memory,
#tray {
    padding-left: 7px;
    padding-right: 7px;
}
'''
    )

    colors = waybar_source / "colors.css"

    if colors.is_file():
        copy_text(
            colors,
            CONFIG
            / "waybar/colors.fallback.css",
        )

    swaync_source = (
        IMPORT_HOME / ".config/swaync"
    )

    copy_text(
        swaync_source / "config.json",
        CONFIG / "swaync/config.json",
    )

    copy_text(
        swaync_source / "style.css",
        CONFIG / "swaync/style.fallback.css",
    )

    swayosd_source = (
        IMPORT_HOME / ".config/swayosd"
    )

    copy_text(
        swayosd_source / "config.toml",
        CONFIG / "swayosd/config.toml",
    )

    copy_text(
        swayosd_source / "style.css",
        CONFIG / "swayosd/style.css",
    )

    matugen_source = (
        IMPORT_HOME / ".config/matugen"
    )

    copy_text(
        matugen_source / "config.toml",
        CONFIG / "matugen/config.toml",
    )

    copy_tree(
        matugen_source / "templates",
        CONFIG / "matugen/templates",
    )

    copy_tree(
        IMPORT_HOME / ".config/fuzzel",
        CONFIG / "fuzzel",
    )

    copy_tree(
        IMPORT_HOME / ".config/kitty",
        CONFIG / "kitty",
    )

    uwsm_source = (
        IMPORT_HOME / ".config/uwsm"
    )

    env_source = uwsm_source / "env"

    if env_source.is_file():
        (
            CONFIG / "uwsm/env.common"
        ).write_text(
            filter_common_uwsm(
                env_source.read_text()
            )
        )
    else:
        (
            CONFIG / "uwsm/env.common"
        ).write_text(
            "export QT_QPA_PLATFORM=wayland;xcb\n"
        )

    env_hyprland = (
        uwsm_source / "env-hyprland"
    )

    if env_hyprland.is_file():
        copy_text(
            env_hyprland,
            CONFIG / "uwsm/env-hyprland.common",
        )
    else:
        (
            CONFIG
            / "uwsm/env-hyprland.common"
        ).write_text(
            "# No universal Hyprland variables.\n"
        )

    (
        GPU_PROFILES / "nvidia.env"
    ).write_text(
        "# NVIDIA GBM and GLX selection\n"
        "export GBM_BACKEND=nvidia-drm\n"
        "export __GLX_VENDOR_LIBRARY_NAME=nvidia\n"
    )

    (
        GPU_PROFILES / "amd.env"
    ).write_text(
        "# AMD uses the standard Mesa/GBM stack.\n"
    )

    (
        GPU_PROFILES / "intel.env"
    ).write_text(
        "# Intel uses the standard Mesa/GBM stack.\n"
    )

    systemd_source = (
        IMPORT_HOME / ".config/systemd/user"
    )

    allowed_units = (
        "swayosd.service",
        "quickshell-overview.service",
        "hyprland-snapshot.service",
        "hyprland-snapshot.timer",
    )

    for unit in allowed_units:
        copy_text(
            systemd_source / unit,
            SYSTEMD / unit,
        )

    waybar_override = (
        systemd_source / "waybar.service.d"
    )

    if waybar_override.is_dir():
        copy_tree(
            waybar_override,
            SYSTEMD / "waybar.service.d",
        )

    script_source = (
        IMPORT_HOME / ".local/bin"
    )

    for name in sorted(collect_script_names()):
        source_path = script_source / name

        if not source_path.is_file():
            continue

        copy_text(
            source_path,
            SCRIPTS / name,
            transform=lambda text, script_name=name: (
                transform_script(
                    script_name,
                    text,
                )
            ),
        )

    write_overview_source()

    docs = REPO / "docs"
    docs.mkdir(parents=True, exist_ok=True)

    (
        docs / "PORTABILITY.md"
    ).write_text(
        """# Portability architecture

The files under `config/` are renderable source files.

Machine-specific tokens:

- `__HOME__`
- `__MONITOR__`
- `__MONITOR_MODE__`
- `__WALLPAPER_DIR__`

The installer renders these tokens into a staging directory before
installing anything into the user's home directory.

Generated Matugen outputs are represented by tracked fallback files and
are regenerated during installation.
"""
    )

    print("Portable source prepared.")
    print()
    print("No live configuration was modified.")


if __name__ == "__main__":
    main()
