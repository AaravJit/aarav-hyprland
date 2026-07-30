#!/usr/bin/env bash
set -Eeuo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dry_run=false
assume_yes=false
skip_packages=false
offline=false
profile="auto"
gpu="auto"
monitor=""
mode=""
scale=""
wallpaper=""
wallpaper_dir="$HOME/Pictures/Wallpapers"
hardware_json=""

services=(
    waybar.service
    swaync.service
    swayosd.service
    hyprpaper.service
    hypridle.service
    hyprsunset.service
    hyprpolkitagent.service
    quickshell-overview.service
    hyprland-snapshot.timer
)

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

  --dry-run
  --yes
  --skip-packages
  --offline
  --profile auto|desktop|laptop
  --gpu auto|nvidia|amd|intel|generic
  --monitor NAME
  --mode MODE
  --scale SCALE
  --wallpaper PATH
  --wallpaper-dir PATH
  --hardware-json PATH
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --yes|-y) assume_yes=true; shift ;;
        --skip-packages) skip_packages=true; shift ;;
        --offline) offline=true; shift ;;
        --profile) profile="${2:?Missing profile}"; shift 2 ;;
        --gpu) gpu="${2:?Missing GPU}"; shift 2 ;;
        --monitor) monitor="${2:?Missing monitor}"; shift 2 ;;
        --mode) mode="${2:?Missing mode}"; shift 2 ;;
        --scale) scale="${2:?Missing scale}"; shift 2 ;;
        --wallpaper) wallpaper="${2:?Missing wallpaper}"; shift 2 ;;
        --wallpaper-dir) wallpaper_dir="${2:?Missing directory}"; shift 2 ;;
        --hardware-json) hardware_json="${2:?Missing JSON path}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$profile" in auto|desktop|laptop) ;; *) echo "Invalid profile" >&2; exit 2 ;; esac
case "$gpu" in auto|nvidia|amd|intel|generic) ;; *) echo "Invalid GPU" >&2; exit 2 ;; esac

[[ "$EUID" -ne 0 ]] || { echo "Do not run as root." >&2; exit 1; }
[[ -f /etc/arch-release ]] || {
    echo "This installer supports Arch-based systems only." >&2
    exit 1
}

for command_name in python git; do
    command -v "$command_name" >/dev/null 2>&1 || {
        echo "Missing bootstrap command: $command_name" >&2
        exit 1
    }
done

work="$(mktemp -d)"
stage="$work/rendered-home"
hardware_file="$work/hardware.json"
backup_created=false
backup_dir=""

cleanup() { rm -rf "$work"; }

rollback() {
    if ! $backup_created || [[ -z "$backup_dir" ]]; then
        return
    fi

    echo
    echo "Installation failed after backup creation; restoring prior state..."

    python "$repo/tools/state-manager.py" restore \
        --home "$HOME" \
        --backup "$backup_dir" \
        >/dev/null 2>&1 || true

    command -v hyprctl >/dev/null 2>&1 \
        && hyprctl reload >/dev/null 2>&1 || true

    echo "Rollback attempted from:"
    echo "  $backup_dir"
}

on_exit() {
    status=$?
    trap - EXIT
    ((status == 0)) || rollback
    cleanup
    exit "$status"
}
trap on_exit EXIT

if [[ -n "$hardware_json" ]]; then
    cp "$hardware_json" "$hardware_file"
else
    "$repo/tools/detect-hardware.py" > "$hardware_file"
fi

if [[ "$gpu" == "auto" ]]; then
    mapfile -t detected_vendors < <(
        python - "$hardware_file" <<'PY'
import json, sys
with open(sys.argv[1]) as file:
    data = json.load(file)
for vendor in dict.fromkeys(data.get("gpu_vendors", [])):
    if vendor in {"nvidia", "amd", "intel"}:
        print(vendor)
PY
    )

    if ((${#detected_vendors[@]} > 1)); then
        echo "Multiple GPU vendors detected:"
        printf '  %s\n' "${detected_vendors[@]}"

        if $assume_yes || [[ ! -t 0 ]]; then
            echo "Rerun with --gpu VENDOR." >&2
            exit 1
        fi

        PS3="Select the GPU driving Hyprland: "
        select selected_gpu in "${detected_vendors[@]}"; do
            [[ -n "$selected_gpu" ]] && { gpu="$selected_gpu"; break; }
        done
    fi
fi

render_arguments=(
    "$repo/tools/render-profile.py"
    --hardware-json "$hardware_file"
    --output "$stage"
    --home "$HOME"
    --profile "$profile"
    --gpu "$gpu"
    --wallpaper-dir "$wallpaper_dir"
    --force
)

[[ -z "$monitor" ]] || render_arguments+=(--monitor "$monitor")
[[ -z "$mode" ]] || render_arguments+=(--mode "$mode")
[[ -z "$scale" ]] || render_arguments+=(--scale "$scale")

python "${render_arguments[@]}"

machine="$stage/.config/aarav-hyprland/machine.json"
mapfile -t resolved < <(
    python - "$machine" <<'PY'
import json, sys
with open(sys.argv[1]) as file:
    data = json.load(file)
for key in ("profile", "gpu", "monitor", "monitor_mode", "monitor_scale"):
    print(data[key])
PY
)

resolved_profile="${resolved[0]}"
resolved_gpu="${resolved[1]}"
resolved_monitor="${resolved[2]}"
resolved_mode="${resolved[3]}"
resolved_scale="${resolved[4]}"

overview="$stage/.config/quickshell/overview"
if [[ ! -f "$overview/shell.qml" ]]; then
    $offline && {
        echo "Overview source absent and --offline was used." >&2
        exit 1
    }

    source_env="$overview/source.env"
    [[ -f "$source_env" ]] || {
        echo "Missing overview source metadata." >&2
        exit 1
    }

    mapfile -t overview_source < <(
        python - "$source_env" <<'PY'
import re, sys
values = {}
for line in open(sys.argv[1]):
    match = re.match(r'([A-Z_]+)=["\047](.*?)["\047]\s*$', line.strip())
    if match:
        values[match.group(1)] = match.group(2)
print(values.get(
    "OVERVIEW_REPOSITORY",
    "https://github.com/Shanu-Kumawat/quickshell-overview.git",
))
print(values.get("OVERVIEW_COMMIT", "UNKNOWN"))
PY
    )

    overview_repository="${overview_source[0]}"
    overview_commit="${overview_source[1]}"

    if [[ "$overview_repository" == git@github.com:* ]]; then
        overview_repository="https://github.com/${overview_repository#git@github.com:}"
    fi

    clone="$work/overview-upstream"
    overlay="$work/overview-overlay"
    mkdir -p "$overlay"
    cp -a "$overview/." "$overlay/"

    echo
    echo "Downloading pinned Quickshell overview source..."
    git clone --quiet "$overview_repository" "$clone"

    if [[ -n "$overview_commit" && "$overview_commit" != "UNKNOWN" ]]; then
        git -C "$clone" checkout --quiet --detach "$overview_commit"
    fi

    rm -rf "$clone/.git" "$overview"
    mv "$clone" "$overview"
    cp -a "$overlay/." "$overview/"
fi

create_default_png() {
    python - "$1" <<'PY'
import binascii, struct, sys, zlib
from pathlib import Path

destination = Path(sys.argv[1])
destination.parent.mkdir(parents=True, exist_ok=True)
width = height = 128
rows = []
for y in range(height):
    row = bytearray([0])
    for x in range(width):
        value = 18 + int((x + y) / 32)
        row.extend((value, value, value + 4))
    rows.append(bytes(row))

def chunk(kind, data):
    return (
        struct.pack(">I", len(data)) + kind + data
        + struct.pack(">I", binascii.crc32(kind + data) & 0xFFFFFFFF)
    )

png = (
    b"\x89PNG\r\n\x1a\n"
    + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    + chunk(b"IDAT", zlib.compress(b"".join(rows), 9))
    + chunk(b"IEND", b"")
)
destination.write_bytes(png)
PY
}

if [[ -n "$wallpaper" ]]; then
    wallpaper="$(realpath -e "$wallpaper")"
else
    current="$(
        find "$HOME/.config/hypr" -maxdepth 1 \
            -name 'wallpaper-current.*' -print -quit 2>/dev/null || true
    )"

    if [[ -n "$current" && -e "$current" ]]; then
        wallpaper="$(readlink -f "$current")"
    else
        wallpaper="$(
            find "$wallpaper_dir" -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o \
                   -iname '*.png' -o -iname '*.webp' \) \
                -print -quit 2>/dev/null || true
        )"
    fi
fi

if [[ -z "$wallpaper" ]]; then
    fallback="$stage/.config/hypr/assets/default.png"
    create_default_png "$fallback"
    wallpaper_target="$HOME/.config/hypr/assets/default.png"
    wallpaper_extension="png"
else
    wallpaper_target="$wallpaper"
    case "${wallpaper##*.}" in
        jpg|JPG) wallpaper_extension="jpg" ;;
        jpeg|JPEG) wallpaper_extension="jpeg" ;;
        png|PNG) wallpaper_extension="png" ;;
        webp|WEBP) wallpaper_extension="webp" ;;
        *) echo "Unsupported wallpaper extension." >&2; exit 1 ;;
    esac
fi

wallpaper_name="wallpaper-current.${wallpaper_extension}"
python - "$stage" "$wallpaper_name" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
replacement = sys.argv[2]
for path in root.rglob("*"):
    if not path.is_file() or path.is_symlink():
        continue
    try:
        raw = path.read_bytes()
        if b"\0" in raw:
            continue
        text = raw.decode("utf-8")
    except (OSError, UnicodeDecodeError):
        continue
    updated = text.replace("wallpaper-current.jpg", replacement)
    if updated != text:
        path.write_text(updated)
PY

find "$stage/.config/hypr" -maxdepth 1 \
    -name 'wallpaper-current.*' -delete
ln -s "$wallpaper_target" "$stage/.config/hypr/$wallpaper_name"

"$repo/tools/validate-render.py" "$stage" \
    --profile "$resolved_profile" \
    --gpu "$resolved_gpu"

declare -A package_set=()
read_manifest() {
    local path="$1"
    [[ -f "$path" ]] || return 0

    while IFS= read -r package; do
        package="$(
            sed \
                -e 's/[[:space:]]*#.*$//' \
                -e 's/^[[:space:]]*//' \
                -e 's/[[:space:]]*$//' \
                <<< "$package"
        )"
        if [[ -n "$package" ]]; then
            package_set["$package"]=1
        fi
    done < "$path"
}

read_manifest "$repo/packages/common.txt"
read_manifest "$repo/packages/${resolved_profile}.txt"
read_manifest "$repo/packages/${resolved_gpu}.txt"
mapfile -t packages < <(printf '%s\n' "${!package_set[@]}" | sort)

missing_packages=()
for package in "${packages[@]}"; do
    pacman -Q "$package" >/dev/null 2>&1 || missing_packages+=("$package")
done

stamp="$(date +%F-%H%M%S)"
backup_root="$HOME/.local/state/aarav-hyprland/install-backups"
planned_backup="$backup_root/$stamp"

echo
echo "========================================"
echo "INSTALLATION PLAN"
echo "========================================"
echo "Profile:        $resolved_profile"
echo "GPU:            $resolved_gpu"
echo "Monitor:        ${resolved_monitor:-<automatic>}"
echo "Mode:           $resolved_mode"
echo "Scale:          $resolved_scale"
echo "Wallpaper:      $wallpaper_target"
echo "Backup:         $planned_backup"
echo "KDE changes:    none"
echo "SDDM changes:   none"
echo "Driver changes: none"
echo
echo "Missing packages:"
((${#missing_packages[@]} == 0)) \
    && echo "  none" \
    || printf '  %s\n' "${missing_packages[@]}"

if $dry_run; then
    echo
    echo "DRY RUN COMPLETE"
    echo "The rendered installation passed validation."
    exit 0
fi

if ! $assume_yes; then
    echo
    read -r -p "Proceed with installation? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Installation cancelled."; exit 0 ;;
    esac
fi

if ((${#missing_packages[@]} > 0)); then
    if $skip_packages; then
        echo "Skipping package installation."
    else
        pacman_args=(sudo pacman -S --needed)
        $assume_yes && pacman_args+=(--noconfirm)
        "${pacman_args[@]}" "${missing_packages[@]}"
    fi
fi

backup_dir="$planned_backup"
mkdir -p "$backup_root"
capture=(
    "$repo/tools/state-manager.py"
    capture
    --home "$HOME"
    --staging "$stage"
    --backup "$backup_dir"
)
for unit in "${services[@]}"; do
    capture+=(--service "$unit")
done
python "${capture[@]}"
backup_created=true

cp "$hardware_file" "$backup_dir/detected-hardware.json"
cp "$machine" "$backup_dir/rendered-machine.json"
git -C "$repo" rev-parse HEAD \
    > "$backup_dir/repository-commit.txt" 2>/dev/null || true

python "$repo/tools/state-manager.py" install \
    --home "$HOME" \
    --staging "$stage"

systemctl --user daemon-reload

enable_unit() {
    local unit="$1"
    systemctl --user enable "$unit" >/dev/null 2>&1 && return 0

    if [[ "$unit" == *.timer ]]; then
        echo "Unable to enable $unit" >&2
        return 1
    fi

    systemctl --user add-wants graphical-session.target "$unit" >/dev/null
}

for unit in "${services[@]}"; do
    enable_unit "$unit"
done

installed_wallpaper="$HOME/.config/hypr/$wallpaper_name"
if command -v matugen >/dev/null 2>&1; then
    matugen image "$installed_wallpaper" || {
        echo "[WARN] Matugen failed; fallback colors remain installed."
    }
fi

case ":${XDG_CURRENT_DESKTOP:-}:" in
    *:Hyprland:*)
        hyprctl reload
        errors="$(hyprctl configerrors 2>&1 | sed '/^[[:space:]]*$/d')"
        [[ -z "$errors" ]] || { printf '%s\n' "$errors" >&2; exit 1; }

        for unit in "${services[@]}"; do
            [[ "$unit" == *.timer ]] && continue

            if systemctl --user is-active --quiet "$unit"; then
                systemctl --user restart "$unit"
            fi
        done
        ;;
esac

if ! "$repo/doctor.sh"; then
    $skip_packages \
        && echo "[WARN] Doctor found issues after --skip-packages." \
        || exit 1
fi

ln -sfn "$backup_dir" "$backup_root/latest"
backup_created=false

echo
echo "========================================"
echo "INSTALLATION COMPLETE"
echo "========================================"
echo "Backup: $backup_dir"
echo "Restore: $repo/restore.sh latest"
echo "At SDDM choose: Hyprland (uwsm-managed)"
