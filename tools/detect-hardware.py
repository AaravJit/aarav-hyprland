#!/usr/bin/env python3

import glob
import json
import os
import subprocess
from typing import Any


def run(command: list[str]) -> str:
    try:
        result = subprocess.run(
            command,
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""

    if result.returncode != 0:
        return ""

    return result.stdout.strip()


def json_command(command: list[str]) -> Any:
    output = run(command)

    if not output:
        return None

    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return None


pci_output = run(["lspci", "-nn"])

display_lines = [
    line
    for line in pci_output.splitlines()
    if any(
        controller in line.lower()
        for controller in (
            "vga compatible controller",
            "3d controller",
            "display controller",
        )
    )
]

vendors: list[str] = []

for line in display_lines:
    lowered = line.lower()

    if (
        "nvidia" in lowered
        or "[10de:" in lowered
    ) and "nvidia" not in vendors:
        vendors.append("nvidia")

    if (
        "amd" in lowered
        or "advanced micro devices" in lowered
        or "ati" in lowered
        or "[1002:" in lowered
    ) and "amd" not in vendors:
        vendors.append("amd")

    if (
        "intel" in lowered
        or "[8086:" in lowered
    ) and "intel" not in vendors:
        vendors.append("intel")


battery_paths = sorted(
    glob.glob("/sys/class/power_supply/BAT*")
)

backlight_paths = sorted(
    glob.glob("/sys/class/backlight/*")
)

monitors_data = json_command(
    ["hyprctl", "monitors", "-j"]
)

monitors: list[dict[str, Any]] = []

if isinstance(monitors_data, list):
    for monitor in monitors_data:
        monitors.append({
            "name": monitor.get("name"),
            "description": monitor.get("description"),
            "width": monitor.get("width"),
            "height": monitor.get("height"),
            "refresh_rate": monitor.get("refreshRate"),
            "scale": monitor.get("scale"),
            "focused": monitor.get("focused"),
            "disabled": monitor.get("disabled"),
        })

primary_monitor = None

for monitor in monitors:
    if monitor.get("focused"):
        primary_monitor = monitor.get("name")
        break

if primary_monitor is None and monitors:
    primary_monitor = monitors[0].get("name")


devices_data = json_command(
    ["hyprctl", "devices", "-j"]
)

touchpads: list[str] = []

if isinstance(devices_data, dict):
    for mouse in devices_data.get("mice", []):
        name = str(mouse.get("name") or "")
        lowered = name.lower()

        if "touchpad" in lowered:
            touchpads.append(name)


is_laptop = bool(
    battery_paths
    or backlight_paths
    or touchpads
)

payload = {
    "hostname": os.uname().nodename,
    "profile": "laptop" if is_laptop else "desktop",
    "gpu_vendors": vendors,
    "display_controllers": display_lines,
    "primary_monitor": primary_monitor,
    "monitors": monitors,
    "has_battery": bool(battery_paths),
    "batteries": [
        os.path.basename(path)
        for path in battery_paths
    ],
    "has_backlight": bool(backlight_paths),
    "backlights": [
        os.path.basename(path)
        for path in backlight_paths
    ],
    "has_touchpad": bool(touchpads),
    "touchpads": touchpads,
}

print(
    json.dumps(
        payload,
        indent=2,
        ensure_ascii=False,
    )
)
