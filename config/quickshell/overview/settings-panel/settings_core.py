from __future__ import annotations

import copy
import json
import os
import tempfile
from pathlib import Path
from typing import Any

HOME = Path.home()
XDG_STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
STATE_DIR = XDG_STATE_HOME / "aarav-hyprland"
SETTINGS_FILE = STATE_DIR / "settings.json"
HYPR_OVERRIDE = HOME / ".config/hypr/generated/user-settings.lua"
FUZZEL_CONFIG = HOME / ".config/fuzzel/fuzzel.ini"
MACHINE_FILE = HOME / ".config/aarav-hyprland/machine.json"
PANEL_DIR = Path(__file__).resolve().parent
PANEL_QML = PANEL_DIR / ".generated-shell.qml"
PANEL_PARTS = tuple(sorted(PANEL_DIR.glob("shell.part*.qml")))

_RENDERED_WALLPAPER_DIR = "__WALLPAPER_DIR__"
DEFAULT_WALLPAPER_DIR = (
    HOME / "Pictures/Wallpapers"
    if _RENDERED_WALLPAPER_DIR.startswith("__")
    else Path(_RENDERED_WALLPAPER_DIR).expanduser()
)

SCHEMES = {
    "scheme-expressive",
    "scheme-tonal-spot",
    "scheme-vibrant",
    "scheme-fidelity",
    "scheme-content",
    "scheme-monochrome",
    "scheme-neutral",
    "scheme-rainbow",
    "scheme-fruit-salad",
}

DEFAULTS: dict[str, Any] = {
    "version": 1,
    "wallpaper": {
        "directories": [
            str(DEFAULT_WALLPAPER_DIR),
            str(HOME / "Pictures"),
            str(HOME / "Downloads"),
        ],
        "mode": "dark",
        "scheme": "scheme-expressive",
        "source_color_index": 0,
    },
    "layout": {
        "gaps_in": 5,
        "gaps_out": 10,
        "border_size": 2,
        "rounding": 12,
        "active_opacity": 0.97,
        "inactive_opacity": 0.92,
    },
    "effects": {
        "blur_enabled": True,
        "blur_size": 7,
        "blur_passes": 3,
        "blur_vibrancy": 0.12,
        "animations_enabled": True,
        "shadow_enabled": True,
        "shadow_range": 4,
        "shadow_power": 3,
        "dim_inactive": True,
        "dim_strength": 0.08,
    },
    "launcher": {
        "width": 52,
        "lines": 9,
        "font_size": 14,
        "line_height": 24,
        "horizontal_pad": 18,
        "vertical_pad": 12,
        "inner_pad": 8,
        "radius": 18,
        "selection_radius": 10,
    },
    "input": {
        "follow_mouse": True,
        "sensitivity": -0.40,
    },
}


def clamp(value: Any, low: float, high: float, *, integer: bool = False) -> int | float:
    try:
        number = float(value)
    except (TypeError, ValueError):
        number = low
    number = max(low, min(high, number))
    return int(round(number)) if integer else round(number, 3)


def as_bool(value: Any, default: bool) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return value != 0
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"true", "yes", "on", "1"}:
            return True
        if lowered in {"false", "no", "off", "0"}:
            return False
    return default


def unique_directories(values: Any) -> list[str]:
    if not isinstance(values, list):
        values = []
    result: list[str] = []
    seen: set[str] = set()
    for value in values[:16]:
        if not isinstance(value, str) or not value.strip():
            continue
        path = os.path.abspath(os.path.expandvars(os.path.expanduser(value.strip())))
        if path not in seen:
            seen.add(path)
            result.append(path)
    return result or [str(DEFAULT_WALLPAPER_DIR)]


def section(source: dict[str, Any], name: str) -> dict[str, Any]:
    value = source.get(name, {})
    return value if isinstance(value, dict) else {}


def normalize(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        raw = {}
    wallpaper = section(raw, "wallpaper")
    layout = section(raw, "layout")
    effects = section(raw, "effects")
    launcher = section(raw, "launcher")
    input_settings = section(raw, "input")

    mode = str(wallpaper.get("mode", "dark"))
    if mode not in {"dark", "light"}:
        mode = "dark"
    scheme = str(wallpaper.get("scheme", "scheme-expressive"))
    if scheme not in SCHEMES:
        scheme = "scheme-expressive"

    normalized = copy.deepcopy(DEFAULTS)
    normalized["wallpaper"] = {
        "directories": unique_directories(
            wallpaper.get("directories", DEFAULTS["wallpaper"]["directories"])
        ),
        "mode": mode,
        "scheme": scheme,
        "source_color_index": clamp(
            wallpaper.get("source_color_index", 0), 0, 15, integer=True
        ),
    }
    normalized["layout"] = {
        "gaps_in": clamp(layout.get("gaps_in", 5), 0, 30, integer=True),
        "gaps_out": clamp(layout.get("gaps_out", 10), 0, 50, integer=True),
        "border_size": clamp(layout.get("border_size", 2), 0, 8, integer=True),
        "rounding": clamp(layout.get("rounding", 12), 0, 30, integer=True),
        "active_opacity": clamp(layout.get("active_opacity", 0.97), 0.60, 1.0),
        "inactive_opacity": clamp(layout.get("inactive_opacity", 0.92), 0.50, 1.0),
    }
    normalized["effects"] = {
        "blur_enabled": as_bool(effects.get("blur_enabled"), True),
        "blur_size": clamp(effects.get("blur_size", 7), 1, 20, integer=True),
        "blur_passes": clamp(effects.get("blur_passes", 3), 1, 8, integer=True),
        "blur_vibrancy": clamp(effects.get("blur_vibrancy", 0.12), 0.0, 1.0),
        "animations_enabled": as_bool(effects.get("animations_enabled"), True),
        "shadow_enabled": as_bool(effects.get("shadow_enabled"), True),
        "shadow_range": clamp(effects.get("shadow_range", 4), 1, 20, integer=True),
        "shadow_power": clamp(effects.get("shadow_power", 3), 1, 4, integer=True),
        "dim_inactive": as_bool(effects.get("dim_inactive"), True),
        "dim_strength": clamp(effects.get("dim_strength", 0.08), 0.0, 0.50),
    }
    normalized["launcher"] = {
        "width": clamp(launcher.get("width", 52), 32, 80, integer=True),
        "lines": clamp(launcher.get("lines", 9), 4, 18, integer=True),
        "font_size": clamp(launcher.get("font_size", 14), 10, 22, integer=True),
        "line_height": clamp(launcher.get("line_height", 24), 18, 44, integer=True),
        "horizontal_pad": clamp(launcher.get("horizontal_pad", 18), 4, 40, integer=True),
        "vertical_pad": clamp(launcher.get("vertical_pad", 12), 4, 30, integer=True),
        "inner_pad": clamp(launcher.get("inner_pad", 8), 2, 24, integer=True),
        "radius": clamp(launcher.get("radius", 18), 0, 32, integer=True),
        "selection_radius": clamp(
            launcher.get("selection_radius", 10), 0, 24, integer=True
        ),
    }
    normalized["input"] = {
        "follow_mouse": as_bool(input_settings.get("follow_mouse"), True),
        "sensitivity": clamp(input_settings.get("sensitivity", -0.40), -1.0, 1.0),
    }
    return normalized


def atomic_write(path: Path, text: str, mode: int = 0o600) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, delete=False
    ) as handle:
        handle.write(text)
        temporary = Path(handle.name)
    temporary.chmod(mode)
    os.replace(temporary, path)


def load_settings() -> dict[str, Any]:
    try:
        raw = json.loads(SETTINGS_FILE.read_text())
    except (OSError, json.JSONDecodeError):
        raw = {}
    return normalize(raw)


def save_settings(settings: dict[str, Any]) -> None:
    atomic_write(SETTINGS_FILE, json.dumps(settings, indent=2) + "\n")


def current_wallpaper() -> Path | None:
    for path in sorted((HOME / ".config/hypr").glob("wallpaper-current.*")):
        try:
            resolved = path.resolve(strict=True)
        except OSError:
            continue
        if resolved.is_file():
            return resolved
    return None


def theme_arguments(settings: dict[str, Any]) -> list[str]:
    wallpaper = settings["wallpaper"]
    return [
        "--mode", wallpaper["mode"],
        "--type", wallpaper["scheme"],
        "--source-color-index", str(wallpaper["source_color_index"]),
    ]


def read_machine() -> dict[str, Any]:
    try:
        data = json.loads(MACHINE_FILE.read_text())
    except (OSError, json.JSONDecodeError):
        return {}
    return data if isinstance(data, dict) else {}


def response(settings: dict[str, Any]) -> dict[str, Any]:
    machine = read_machine()
    wallpaper = current_wallpaper()
    system = {
        "profile": machine.get("profile", "unknown"),
        "gpu": machine.get("gpu", "unknown"),
        "monitor": machine.get("monitor", "unknown"),
        "monitor_mode": machine.get("monitor_mode", "unknown"),
        "monitor_scale": machine.get("monitor_scale", "unknown"),
        "current_wallpaper": str(wallpaper) if wallpaper else "",
        "settings_file": str(SETTINGS_FILE),
        "directories": [
            {"path": path, "exists": Path(path).is_dir()}
            for path in settings["wallpaper"]["directories"]
        ],
    }
    return {"settings": settings, "system": system}


def print_json(settings: dict[str, Any]) -> None:
    print(json.dumps(response(settings), separators=(",", ":")))
