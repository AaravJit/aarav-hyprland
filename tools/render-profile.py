#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from typing import Any


REPO = Path(__file__).resolve().parents[1]

TOKENS = {
    "__HOME__",
    "__MONITOR__",
    "__MONITOR_MODE__",
    "__MONITOR_SCALE__",
    "__WALLPAPER_DIR__",
}


def run(command: list[str]) -> str:
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=8,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""

    if result.returncode != 0:
        return ""

    return result.stdout.strip()


def load_hardware(path: Path | None) -> dict[str, Any]:
    if path is not None:
        with path.open() as file:
            data = json.load(file)

        if not isinstance(data, dict):
            raise SystemExit(
                "Hardware JSON must contain one object."
            )

        return data

    output = run([
        sys.executable,
        str(REPO / "tools/detect-hardware.py"),
    ])

    if not output:
        raise SystemExit(
            "Hardware detection returned no data."
        )

    try:
        data = json.loads(output)
    except json.JSONDecodeError as error:
        raise SystemExit(
            f"Hardware detection returned invalid JSON: {error}"
        ) from error

    if not isinstance(data, dict):
        raise SystemExit(
            "Hardware detection did not return an object."
        )

    return data


def connected_drm_outputs() -> list[str]:
    outputs: list[str] = []

    for status_path in sorted(
        Path("/sys/class/drm").glob("card*-*/status")
    ):
        try:
            status = status_path.read_text().strip()
        except OSError:
            continue

        if status != "connected":
            continue

        connector = status_path.parent.name

        # card0-eDP-1 -> eDP-1
        if "-" in connector:
            connector = connector.split("-", 1)[1]

        outputs.append(connector)

    outputs.sort(
        key=lambda name: (
            not name.startswith("eDP-"),
            name,
        )
    )

    return outputs


def resolve_monitor(
    hardware: dict[str, Any],
    requested: str | None,
    profile: str,
) -> str:
    if requested:
        return requested

    detected = hardware.get("primary_monitor")

    if isinstance(detected, str) and detected:
        return detected

    connected = connected_drm_outputs()

    if connected:
        return connected[0]

    if profile == "laptop":
        # Common fallback if rendering somewhere without a running
        # Hyprland session and sysfs connector information is absent.
        return "eDP-1"

    # Empty output matches any monitor in Hyprland.
    return ""


def matching_monitor(
    hardware: dict[str, Any],
    name: str,
) -> dict[str, Any] | None:
    monitors = hardware.get("monitors")

    if not isinstance(monitors, list):
        return None

    for monitor in monitors:
        if (
            isinstance(monitor, dict)
            and monitor.get("name") == name
        ):
            return monitor

    return None


def format_refresh(value: Any) -> str | None:
    try:
        refresh = float(value)
    except (TypeError, ValueError):
        return None

    if refresh <= 0:
        return None

    if refresh.is_integer():
        return str(int(refresh))

    return f"{refresh:.3f}".rstrip("0").rstrip(".")


def resolve_mode(
    hardware: dict[str, Any],
    monitor_name: str,
    requested: str | None,
) -> str:
    if requested:
        return requested

    monitor = matching_monitor(
        hardware,
        monitor_name,
    )

    if monitor:
        width = monitor.get("width")
        height = monitor.get("height")
        refresh = format_refresh(
            monitor.get("refresh_rate")
        )

        if (
            isinstance(width, int)
            and width > 0
            and isinstance(height, int)
            and height > 0
            and refresh
        ):
            return f"{width}x{height}@{refresh}"

    return "preferred"


def resolve_scale(
    hardware: dict[str, Any],
    monitor_name: str,
    requested: str | None,
    profile: str,
) -> str:
    if requested:
        return requested

    monitor = matching_monitor(
        hardware,
        monitor_name,
    )

    if monitor:
        try:
            scale = float(monitor.get("scale"))
        except (TypeError, ValueError):
            scale = 0

        if scale > 0:
            if scale.is_integer():
                return str(int(scale))

            return (
                f"{scale:.3f}"
                .rstrip("0")
                .rstrip(".")
            )

    return "auto" if profile == "laptop" else "1"


def resolve_profile(
    hardware: dict[str, Any],
    requested: str,
) -> str:
    if requested != "auto":
        return requested

    detected = hardware.get("profile")

    if detected in {"desktop", "laptop"}:
        return str(detected)

    return (
        "laptop"
        if hardware.get("has_battery")
        else "desktop"
    )


def resolve_gpu(
    hardware: dict[str, Any],
    requested: str,
) -> str:
    if requested != "auto":
        return requested

    vendors = hardware.get("gpu_vendors")

    if not isinstance(vendors, list):
        vendors = []

    vendors = [
        str(vendor)
        for vendor in vendors
        if vendor in {
            "nvidia",
            "amd",
            "intel",
        }
    ]

    vendors = list(dict.fromkeys(vendors))

    if len(vendors) == 1:
        return vendors[0]

    if len(vendors) > 1:
        raise SystemExit(
            "Multiple GPU vendors were detected: "
            + ", ".join(vendors)
            + "\nSelect the compositor-driving GPU with "
            "--gpu nvidia, --gpu amd, or --gpu intel."
        )

    return "generic"


def replace_tokens(
    text: str,
    values: dict[str, str],
) -> str:
    for token, value in values.items():
        text = text.replace(token, value)

    return text


def copy_rendered_tree(
    source: Path,
    destination: Path,
    values: dict[str, str],
) -> None:
    if not source.is_dir():
        return

    for path in source.rglob("*"):
        relative = path.relative_to(source)
        target = destination / relative

        if path.is_dir():
            target.mkdir(
                parents=True,
                exist_ok=True,
            )
            continue

        if not path.is_file():
            continue

        target.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        raw = path.read_bytes()

        if b"\0" in raw:
            target.write_bytes(raw)
        else:
            text = raw.decode(
                "utf-8",
                errors="strict",
            )

            target.write_text(
                replace_tokens(
                    text,
                    values,
                )
            )

        target.chmod(
            stat.S_IMODE(path.stat().st_mode)
        )


def promote_file(
    directory: Path,
    source_name: str,
    destination_name: str,
) -> None:
    source = directory / source_name
    destination = directory / destination_name

    if not source.is_file():
        raise SystemExit(
            f"Missing render source: {source}"
        )

    shutil.copy2(
        source,
        destination,
    )


def remove_matching(
    directory: Path,
    patterns: tuple[str, ...],
) -> None:
    for pattern in patterns:
        for path in directory.glob(pattern):
            if path.is_file() or path.is_symlink():
                path.unlink()


def shell_join_env(
    common_path: Path,
    gpu_path: Path | None,
    destination: Path,
) -> None:
    sections: list[str] = []

    if common_path.is_file():
        sections.append(
            common_path.read_text().rstrip()
        )

    if gpu_path and gpu_path.is_file():
        sections.append(
            gpu_path.read_text().rstrip()
        )

    destination.write_text(
        "\n\n".join(
            section
            for section in sections
            if section
        )
        + "\n"
    )


def command_with_monitor(
    monitor: str,
    command: str,
) -> str:
    if monitor:
        return (
            "swayosd-client "
            f"--monitor {monitor} "
            f"{command}"
        )

    return f"swayosd-client {command}"


def create_hardware_lua(
    destination: Path,
    *,
    profile: str,
    gpu: str,
    monitor: str,
    mode: str,
    scale: str,
    has_battery: bool,
    has_backlight: bool,
    has_touchpad: bool,
    main_lua: str,
) -> None:
    lines = [
        "--------------------------------",
        "-- Generated machine configuration",
        "--------------------------------",
        "",
        "-- Do not edit this file directly.",
        "-- It is recreated by the installer.",
        "",
        "local machine = {",
        f'    profile = "{profile}",',
        f'    gpu = "{gpu}",',
        f'    monitor = "{monitor}",',
        f'    mode = "{mode}",',
        f'    scale = "{scale}",',
        (
            "    has_battery = "
            + str(has_battery).lower()
            + ","
        ),
        (
            "    has_backlight = "
            + str(has_backlight).lower()
            + ","
        ),
        (
            "    has_touchpad = "
            + str(has_touchpad).lower()
            + ","
        ),
        "}",
        "",
    ]

    if has_touchpad or profile == "laptop":
        lines.extend([
            "hl.config({",
            "    input = {",
            "        touchpad = {",
            "            tap_to_click = true,",
            "            natural_scroll = true,",
            "            disable_while_typing = true,",
            "        },",
            "    },",
            "})",
            "",
        ])

    # Avoid creating duplicate brightness bindings if they already
    # exist in the shared configuration.
    if (
        has_backlight
        and "XF86MonBrightnessUp" not in main_lua
    ):
        up = command_with_monitor(
            monitor,
            "--brightness +5",
        )

        down = command_with_monitor(
            monitor,
            "--brightness -5",
        )

        lines.extend([
            "hl.bind(",
            '    "XF86MonBrightnessUp",',
            f"    hl.dsp.exec_cmd({json.dumps(up)}),",
            "    {",
            "        locked = true,",
            "        repeating = true,",
            '        description = "Brightness up",',
            "    }",
            ")",
            "",
            "hl.bind(",
            '    "XF86MonBrightnessDown",',
            f"    hl.dsp.exec_cmd({json.dumps(down)}),",
            "    {",
            "        locked = true,",
            "        repeating = true,",
            '        description = "Brightness down",',
            "    }",
            ")",
            "",
        ])

    destination.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    destination.write_text(
        "\n".join(lines)
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Render Aarav Hyprland into an isolated home tree."
        )
    )

    parser.add_argument(
        "--hardware-json",
        type=Path,
    )

    parser.add_argument(
        "--output",
        type=Path,
        required=True,
    )

    parser.add_argument(
        "--home",
        type=Path,
        required=True,
        help=(
            "Home path embedded into the rendered configuration."
        ),
    )

    parser.add_argument(
        "--profile",
        choices=[
            "auto",
            "desktop",
            "laptop",
        ],
        default="auto",
    )

    parser.add_argument(
        "--gpu",
        choices=[
            "auto",
            "nvidia",
            "amd",
            "intel",
            "generic",
        ],
        default="auto",
    )

    parser.add_argument("--monitor")
    parser.add_argument("--mode")
    parser.add_argument("--scale")

    parser.add_argument(
        "--wallpaper-dir",
        type=Path,
    )

    parser.add_argument(
        "--force",
        action="store_true",
    )

    args = parser.parse_args()

    hardware = load_hardware(
        args.hardware_json
    )

    profile = resolve_profile(
        hardware,
        args.profile,
    )

    gpu = resolve_gpu(
        hardware,
        args.gpu,
    )

    monitor = resolve_monitor(
        hardware,
        args.monitor,
        profile,
    )

    mode = resolve_mode(
        hardware,
        monitor,
        args.mode,
    )

    scale = resolve_scale(
        hardware,
        monitor,
        args.scale,
        profile,
    )

    rendered_home = args.home.expanduser()

    wallpaper_dir = (
        args.wallpaper_dir.expanduser()
        if args.wallpaper_dir
        else rendered_home / "Pictures/Wallpapers"
    )

    output = args.output.resolve()

    if output.exists():
        if not args.force:
            raise SystemExit(
                f"Output already exists: {output}\n"
                "Pass --force to replace it."
            )

        shutil.rmtree(output)

    output.mkdir(
        parents=True,
        exist_ok=True,
    )

    values = {
        "__HOME__": str(rendered_home),
        "__MONITOR__": monitor,
        "__MONITOR_MODE__": mode,
        "__MONITOR_SCALE__": scale,
        "__WALLPAPER_DIR__": str(wallpaper_dir),
    }

    copy_rendered_tree(
        REPO / "config",
        output / ".config",
        values,
    )

    gpu_status_source = REPO / "scripts/gpu-status"

    if not gpu_status_source.is_file():
        raise SystemExit(
            "Missing required source file: "
            "scripts/gpu-status"
        )

    copy_rendered_tree(
        REPO / "scripts",
        output / ".local/bin",
        values,
    )

    copy_rendered_tree(
        REPO / "systemd/user",
        output / ".config/systemd/user",
        values,
    )

    waybar = output / ".config/waybar"

    promote_file(
        waybar,
        f"config.{profile}.jsonc",
        "config.jsonc",
    )

    promote_file(
        waybar,
        f"config-gaming.{profile}.jsonc",
        "config-gaming.jsonc",
    )

    promote_file(
        waybar,
        f"profile.{profile}.css",
        "profile.css",
    )

    promote_file(
        waybar,
        "colors.fallback.css",
        "colors.css",
    )

    remove_matching(
        waybar,
        (
            "config.desktop.jsonc",
            "config.laptop.jsonc",
            "config-gaming.desktop.jsonc",
            "config-gaming.laptop.jsonc",
            "profile.desktop.css",
            "profile.laptop.css",
            "colors.fallback.css",
        ),
    )

    hypr = output / ".config/hypr"

    promote_file(
        hypr,
        "matugen.fallback.lua",
        "matugen.lua",
    )

    promote_file(
        hypr,
        "hyprlock-colors.fallback.conf",
        "hyprlock-colors.conf",
    )

    remove_matching(
        hypr,
        (
            "matugen.fallback.lua",
            "hyprlock-colors.fallback.conf",
        ),
    )

    swaync = output / ".config/swaync"

    promote_file(
        swaync,
        "style.fallback.css",
        "style.css",
    )

    remove_matching(
        swaync,
        ("style.fallback.css",),
    )

    overview = (
        output / ".config/quickshell/overview"
    )

    promote_file(
        overview,
        f"config.{profile}.json",
        "config.json",
    )

    remove_matching(
        overview,
        (
            "config.desktop.json",
            "config.laptop.json",
        ),
    )

    appearance_fallback = (
        overview
        / "Appearance.colors.fallback.qml"
    )

    if appearance_fallback.is_file():
        appearance_destination = (
            overview
            / "common/Appearance.colors.qml"
        )

        appearance_destination.parent.mkdir(
            parents=True,
            exist_ok=True,
        )

        shutil.copy2(
            appearance_fallback,
            appearance_destination,
        )

        appearance_fallback.unlink()

    uwsm = output / ".config/uwsm"
    env_common = uwsm / "env.common"

    gpu_env = (
        REPO / f"profiles/gpu/{gpu}.env"
    )

    if not gpu_env.is_file():
        gpu_env = None

    shell_join_env(
        env_common,
        gpu_env,
        uwsm / "env",
    )

    env_hyprland_common = (
        uwsm / "env-hyprland.common"
    )

    if env_hyprland_common.is_file():
        shutil.copy2(
            env_hyprland_common,
            uwsm / "env-hyprland",
        )

    remove_matching(
        uwsm,
        (
            "env.common",
            "env-hyprland.common",
        ),
    )

    main_lua_path = (
        output / ".config/hypr/hyprland.lua"
    )

    main_lua = (
        main_lua_path.read_text()
        if main_lua_path.is_file()
        else ""
    )

    if 'require("generated.hardware")' not in main_lua:
        raise SystemExit(
            "Rendered hyprland.lua does not load "
            "generated.hardware."
        )

    create_hardware_lua(
        output
        / ".config/hypr/generated/hardware.lua",
        profile=profile,
        gpu=gpu,
        monitor=monitor,
        mode=mode,
        scale=scale,
        has_battery=bool(
            hardware.get("has_battery")
        ),
        has_backlight=bool(
            hardware.get("has_backlight")
        ),
        has_touchpad=bool(
            hardware.get("has_touchpad")
        ),
        main_lua=main_lua,
    )

    metadata = {
        "profile": profile,
        "gpu": gpu,
        "monitor": monitor,
        "monitor_mode": mode,
        "monitor_scale": scale,
        "home": str(rendered_home),
        "wallpaper_directory": str(wallpaper_dir),
        "has_battery": bool(
            hardware.get("has_battery")
        ),
        "has_backlight": bool(
            hardware.get("has_backlight")
        ),
        "has_touchpad": bool(
            hardware.get("has_touchpad")
        ),
        "hardware": hardware,
    }

    metadata_path = (
        output
        / ".config/aarav-hyprland/machine.json"
    )

    metadata_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    metadata_path.write_text(
        json.dumps(
            metadata,
            indent=2,
            ensure_ascii=False,
        )
        + "\n"
    )

    for script in (
        output / ".local/bin"
    ).glob("*"):
        if script.is_file():
            script.chmod(
                script.stat().st_mode
                | stat.S_IXUSR
            )

    print("Rendered profile successfully.")
    print()
    print(f"Profile:  {profile}")
    print(f"GPU:      {gpu}")
    print(f"Monitor:  {monitor or '<any>'}")
    print(f"Mode:     {mode}")
    print(f"Scale:    {scale}")
    print(f"Home:     {rendered_home}")
    print(f"Output:   {output}")


if __name__ == "__main__":
    main()
