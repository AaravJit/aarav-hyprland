#!/usr/bin/env python3

import glob
import json
import os
import re
import subprocess
from typing import Any


PCI_VENDOR_MAP = {
    "10de": "nvidia",
    "1002": "amd",
    "8086": "intel",
}


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


def detect_vendor(line: str) -> str | None:
    """Detect a display controller vendor without substring false positives."""

    lowered = line.lower()

    # Prefer the actual PCI vendor ID, for example [10de:2882].
    for vendor_id, _device_id in re.findall(
        r"\[([0-9a-fA-F]{4}):([0-9a-fA-F]{4})\]",
        line,
    ):
        vendor = PCI_VENDOR_MAP.get(vendor_id.lower())

        if vendor:
            return vendor

    # Conservative fallback for unusual lspci output.
    if re.search(r"\bnvidia\b", lowered):
        return "nvidia"

    if re.search(
        r"\badvanced micro devices\b|\bamd/ati\b|\bati technologies\b",
        lowered,
    ):
        return "amd"

    if re.search(r"\bintel\b", lowered):
        return "intel"

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
    vendor = detect_vendor(line)

    if vendor and vendor not in vendors:
        vendors.append(vendor)


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

        if "touchpad" in name.lower():
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
