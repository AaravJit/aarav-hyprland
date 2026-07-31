#!/usr/bin/env bash
set -uo pipefail

home="$HOME"
strict=false

while (($#)); do
    case "$1" in
        --home)
            home="${2:?Missing path after --home}"
            shift 2
            ;;
        --strict)
            strict=true
            shift
            ;;
        -h|--help)
            echo "Usage: ./doctor.sh [--home PATH] [--strict]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

home="$(realpath -m "$home")"
failures=0
warnings=0

pass() { printf '[PASS] %s\n' "$1"; }
warn() { printf '[WARN] %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf '[FAIL] %s\n' "$1"; failures=$((failures + 1)); }

machine="$home/.config/aarav-hyprland/machine.json"

echo "========================================"
echo "AARAV HYPRLAND INSTALL DOCTOR"
echo "========================================"
echo "Home: $home"

profile="unknown"
gpu="unknown"

if [[ -f "$machine" ]]; then
    if values="$(
        python - "$machine" <<'PY'
import json, sys
with open(sys.argv[1]) as file:
    data = json.load(file)
print(data.get("profile", "unknown"))
print(data.get("gpu", "unknown"))
PY
    )"; then
        mapfile -t machine_values <<< "$values"
        profile="${machine_values[0]}"
        gpu="${machine_values[1]}"
        pass "Machine metadata is valid"
    else
        fail "Machine metadata is invalid"
    fi
else
    fail "Missing machine metadata"
fi

echo
echo "Profile: $profile"
echo "GPU:     $gpu"

echo
echo "--- Required commands ---"

commands=(
    hyprctl uwsm waybar nwg-bar swaync-client swayosd-client
    hyprlock hypridle hyprpaper hyprsunset qs matugen
    fuzzel kitty playerctl wpctl nmcli nvtop wl-copy
    cliphist grim slurp swappy python luac
)

[[ "$profile" == "laptop" ]] && commands+=(brightnessctl)

for command_name in "${commands[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
        pass "$command_name"
    else
        fail "Missing command: $command_name"
    fi
done

if [[ "$gpu" == "nvidia" ]]; then
    command -v nvidia-smi >/dev/null 2>&1 \
        && pass "nvidia-smi" \
        || warn "nvidia-smi unavailable; GPU details will be limited"
fi

echo
echo "--- Required files ---"

required_files=(
    ".config/hypr/hyprland.lua"
    ".config/hypr/generated/hardware.lua"
    ".config/hypr/hyprlock.conf"
    ".config/hypr/hypridle.conf"
    ".config/hypr/hyprpaper.conf"
    ".config/waybar/config.jsonc"
    ".config/waybar/config-gaming.jsonc"
    ".config/waybar/style.css"
    ".config/waybar/colors.css"
    ".config/nwg-bar/bar.json"
    ".config/nwg-bar/style.css"
    ".config/swaync/config.json"
    ".config/swaync/style.css"
    ".config/swayosd/config.toml"
    ".config/matugen/config.toml"
    ".config/quickshell/overview/config.json"
    ".config/quickshell/overview/shell.qml"
    ".config/uwsm/env"
    ".local/bin/gpu-status"
    ".local/bin/gaming-mode"
    ".local/bin/hypr-health"
    ".local/bin/hypr-safe-reload"
)

for relative in "${required_files[@]}"; do
    [[ -f "$home/$relative" ]] \
        && pass "$relative" \
        || fail "Missing $relative"
done

echo
echo "--- Lua syntax ---"

while IFS= read -r -d '' file; do
    if luac -p "$file" >/dev/null 2>&1; then
        pass "${file#"$home/"}"
    else
        fail "Lua syntax error: ${file#"$home/"}"
        luac -p "$file" 2>&1 || true
    fi
done < <(
    find "$home/.config/hypr" -type f -name '*.lua' -print0 2>/dev/null
)

echo
echo "--- Structured files ---"

if python - "$home" <<'PY' >/dev/null
import json, sys, tomllib
from pathlib import Path

home = Path(sys.argv[1])
for path in (
    home / ".config/swaync/config.json",
    home / ".config/quickshell/overview/config.json",
    home / ".config/aarav-hyprland/machine.json",
):
    with path.open() as file:
        json.load(file)

for path in (
    home / ".config/swayosd/config.toml",
    home / ".config/matugen/config.toml",
):
    with path.open("rb") as file:
        tomllib.load(file)
PY
then
    pass "JSON and TOML files are valid"
else
    fail "One or more JSON/TOML files are invalid"
fi

echo
echo "--- Render state ---"

unresolved="$(
    grep -RInI -E '__[A-Z][A-Z0-9_]+__' \
        "$home/.config/hypr" \
        "$home/.config/waybar" \
        "$home/.config/swaync" \
        "$home/.config/swayosd" \
        "$home/.config/matugen" \
        "$home/.config/quickshell/overview" \
        "$home/.local/bin" \
        2>/dev/null || true
)"

if [[ -z "$unresolved" ]]; then
    pass "No unresolved render tokens"
else
    fail "Unresolved render tokens found"
    printf '%s\n' "$unresolved"
fi

wallpaper="$(
    find "$home/.config/hypr" -maxdepth 1 \
        -name 'wallpaper-current.*' -print -quit 2>/dev/null
)"

if [[ -z "$wallpaper" ]]; then
    fail "No wallpaper-current link found"
elif [[ -e "$wallpaper" ]]; then
    pass "Wallpaper target resolves"
else
    fail "Wallpaper link is broken"
fi

echo
echo "--- Profile behavior ---"

waybar="$home/.config/waybar/config.jsonc"
uwsm_env="$home/.config/uwsm/env"
hardware="$home/.config/hypr/generated/hardware.lua"

grep -q '"custom/gpu"' "$waybar" 2>/dev/null \
    && pass "Waybar uses cross-vendor GPU module" \
    || fail "Waybar cross-vendor GPU module missing"

if [[ "$profile" == "laptop" ]]; then
    for module in battery backlight; do
        grep -q "\"$module\"" "$waybar" 2>/dev/null \
            && pass "Laptop Waybar includes $module" \
            || fail "Laptop Waybar missing $module"
    done

    grep -q touchpad "$hardware" 2>/dev/null \
        && pass "Laptop touchpad configuration exists" \
        || fail "Laptop touchpad configuration missing"
fi

has_nvidia_env=false
grep -Eq 'GBM_BACKEND=nvidia|__GLX_VENDOR_LIBRARY_NAME=nvidia' \
    "$uwsm_env" 2>/dev/null && has_nvidia_env=true

if [[ "$gpu" == "nvidia" ]]; then
    $has_nvidia_env \
        && pass "NVIDIA UWSM environment present" \
        || fail "NVIDIA UWSM environment missing"
else
    $has_nvidia_env \
        && fail "$gpu profile contains NVIDIA-only environment" \
        || pass "$gpu profile contains no NVIDIA-only environment"
fi

echo
echo "--- Session isolation ---"

session_services=(
    waybar.service swaync.service swayosd.service
    hyprpaper.service hypridle.service hyprsunset.service
    hyprpolkitagent.service quickshell-overview.service
)

for unit in "${session_services[@]}"; do
    dropin="$home/.config/systemd/user/${unit}.d/10-aarav-hyprland-session.conf"
    [[ -f "$dropin" ]] \
        && pass "$unit is scoped to Hyprland" \
        || fail "Missing session guard for $unit"
done

echo
echo "--- Runtime ---"

case ":${XDG_CURRENT_DESKTOP:-}:" in
    *:Hyprland:*)
        errors="$(hyprctl configerrors 2>&1 | sed '/^[[:space:]]*$/d')"
        [[ -z "$errors" ]] \
            && pass "Hyprland reports no configuration errors" \
            || { fail "Hyprland reports configuration errors"; printf '%s\n' "$errors"; }
        ;;
    *)
        pass "Not inside Hyprland; runtime checks skipped"
        ;;
esac

echo
echo "--- Installer backups ---"

backup_root="$home/.local/state/aarav-hyprland/install-backups"
latest="$(readlink -f "$backup_root/latest" 2>/dev/null || true)"

if [[ -n "$latest" && -f "$latest/manifest.json" ]]; then
    pass "Latest installer backup exists"
else
    warn "No completed installer backup recorded yet"
fi

echo
echo "========================================"

if $strict && ((warnings > 0)); then
    failures=$((failures + warnings))
fi

if ((failures == 0)); then
    ((warnings == 0)) \
        && echo "RESULT: HEALTHY" \
        || echo "RESULT: HEALTHY WITH $warnings WARNING(S)"
    exit 0
fi

echo "RESULT: $failures FAILURE(S), $warnings WARNING(S)"
exit 1
