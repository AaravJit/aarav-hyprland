#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path


TOKEN_PATTERN = re.compile(
    r"__[A-Z][A-Z0-9_]+__"
)


def pass_result(message: str) -> None:
    print(f"[PASS] {message}")


def fail_result(
    failures: list[str],
    message: str,
) -> None:
    failures.append(message)
    print(f"[FAIL] {message}")


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "root",
        type=Path,
    )

    parser.add_argument(
        "--profile",
        choices=[
            "desktop",
            "laptop",
        ],
        required=True,
    )

    parser.add_argument(
        "--gpu",
        choices=[
            "nvidia",
            "amd",
            "intel",
            "generic",
        ],
        required=True,
    )

    args = parser.parse_args()
    root = args.root.resolve()

    failures: list[str] = []

    print("========================================")
    print("PORTABLE RENDER VALIDATION")
    print("========================================")
    print(f"Root:    {root}")
    print(f"Profile: {args.profile}")
    print(f"GPU:     {args.gpu}")

    required = [
        ".config/hypr/hyprland.lua",
        ".config/hypr/generated/hardware.lua",
        ".config/hypr/hyprlock.conf",
        ".config/hypr/hypridle.conf",
        ".config/hypr/hyprpaper.conf",
        ".config/waybar/config.jsonc",
        ".config/waybar/config-gaming.jsonc",
        ".config/waybar/style.css",
        ".config/waybar/colors.css",
        ".config/swaync/config.json",
        ".config/swaync/style.css",
        ".config/swayosd/config.toml",
        ".config/matugen/config.toml",
        ".config/quickshell/overview/config.json",
        ".config/uwsm/env",
        ".config/aarav-hyprland/machine.json",
        ".local/bin/gpu-status",
        ".local/bin/gaming-mode",
        ".local/bin/hypr-health",
    ]

    print()
    print("--- Required files ---")

    for relative in required:
        path = root / relative

        if path.is_file():
            pass_result(relative)
        else:
            fail_result(
                failures,
                f"Missing {relative}",
            )

    print()
    print("--- Unresolved render tokens ---")

    unresolved: list[str] = []

    for path in root.rglob("*"):
        if not path.is_file():
            continue

        try:
            raw = path.read_bytes()
        except OSError:
            continue

        if b"\0" in raw:
            continue

        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            continue

        matches = sorted(
            set(TOKEN_PATTERN.findall(text))
        )

        if matches:
            unresolved.append(
                f"{path.relative_to(root)}: "
                + ", ".join(matches)
            )

    if unresolved:
        for item in unresolved:
            fail_result(failures, item)
    else:
        pass_result("No unresolved tokens")

    print()
    print("--- Lua syntax ---")

    lua_files = sorted(
        (root / ".config/hypr").rglob("*.lua")
    )

    for path in lua_files:
        result = run([
            "luac",
            "-p",
            str(path),
        ])

        if result.returncode == 0:
            pass_result(
                str(path.relative_to(root))
            )
        else:
            fail_result(
                failures,
                (
                    f"Lua syntax: "
                    f"{path.relative_to(root)}\n"
                    f"{result.stderr.strip()}"
                ),
            )

    print()
    print("--- JSON and TOML ---")

    json_files = [
        root / ".config/swaync/config.json",
        (
            root
            / ".config/quickshell/overview/config.json"
        ),
        (
            root
            / ".config/aarav-hyprland/machine.json"
        ),
    ]

    for path in json_files:
        try:
            with path.open() as file:
                json.load(file)

            pass_result(
                str(path.relative_to(root))
            )
        except (
            OSError,
            json.JSONDecodeError,
        ) as error:
            fail_result(
                failures,
                (
                    f"Invalid JSON "
                    f"{path.relative_to(root)}: {error}"
                ),
            )

    toml_files = [
        root / ".config/swayosd/config.toml",
        root / ".config/matugen/config.toml",
    ]

    for path in toml_files:
        try:
            with path.open("rb") as file:
                tomllib.load(file)

            pass_result(
                str(path.relative_to(root))
            )
        except (
            OSError,
            tomllib.TOMLDecodeError,
        ) as error:
            fail_result(
                failures,
                (
                    f"Invalid TOML "
                    f"{path.relative_to(root)}: {error}"
                ),
            )

    print()
    print("--- Script permissions ---")

    scripts = root / ".local/bin"

    if scripts.is_dir():
        for path in sorted(scripts.iterdir()):
            if not path.is_file():
                continue

            if os.access(path, os.X_OK):
                pass_result(
                    f"{path.name} is executable"
                )
            else:
                fail_result(
                    failures,
                    f"{path.name} is not executable",
                )

    print()
    print("--- Profile behavior ---")

    waybar_text = (
        root
        / ".config/waybar/config.jsonc"
    ).read_text()

    hardware_text = (
        root
        / ".config/hypr/generated/hardware.lua"
    ).read_text()

    uwsm_text = (
        root
        / ".config/uwsm/env"
    ).read_text()

    if args.profile == "laptop":
        for module in (
            '"battery"',
            '"backlight"',
        ):
            if module in waybar_text:
                pass_result(
                    f"Laptop Waybar includes {module}"
                )
            else:
                fail_result(
                    failures,
                    (
                        "Laptop Waybar is missing "
                        f"{module}"
                    ),
                )

        if "touchpad" in hardware_text:
            pass_result(
                "Laptop hardware file configures touchpad"
            )
        else:
            fail_result(
                failures,
                "Laptop touchpad configuration is absent",
            )

    else:
        if '"battery"' not in waybar_text:
            pass_result(
                "Desktop bar omits battery module"
            )
        else:
            fail_result(
                failures,
                "Desktop bar unexpectedly includes battery",
            )

    has_nvidia_env = (
        "GBM_BACKEND=nvidia-drm" in uwsm_text
        or "__GLX_VENDOR_LIBRARY_NAME=nvidia"
        in uwsm_text
    )

    if args.gpu == "nvidia":
        if has_nvidia_env:
            pass_result(
                "NVIDIA UWSM environment is present"
            )
        else:
            fail_result(
                failures,
                "NVIDIA UWSM environment is missing",
            )
    else:
        if not has_nvidia_env:
            pass_result(
                (
                    f"{args.gpu.upper()} render "
                    "contains no NVIDIA environment"
                )
            )
        else:
            fail_result(
                failures,
                (
                    f"{args.gpu.upper()} render "
                    "contains NVIDIA-only environment"
                ),
            )

    gpu_status = (
        root / ".local/bin/gpu-status"
    ).read_text()

    for backend in (
        "nvidia",
        "amd",
        "intel",
    ):
        if backend in gpu_status.lower():
            pass_result(
                f"GPU status includes {backend} backend"
            )
        else:
            fail_result(
                failures,
                (
                    "GPU status is missing "
                    f"{backend} handling"
                ),
            )

    print()
    print("========================================")

    if failures:
        print(
            f"RESULT: {len(failures)} ISSUE(S) FOUND"
        )
        raise SystemExit(1)

    print("RESULT: VALID")


if __name__ == "__main__":
    main()
