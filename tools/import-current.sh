#!/usr/bin/env bash
set -euo pipefail

repo="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

destination="$repo/.local-import/home"

echo "Creating an ignored working import at:"
echo "$destination"

rm -rf "$destination"

mkdir -p \
    "$destination/.config" \
    "$destination/.local/bin" \
    "$repo/.local-import/manifests"

config_paths=(
    "hypr"
    "waybar"
    "swaync"
    "swayosd"
    "fuzzel"
    "kitty"
    "matugen"
    "quickshell/overview"
    "systemd/user"
    "uwsm"
    "gtk-3.0"
    "gtk-4.0"
    "qt5ct"
    "qt6ct"
    "Kvantum"
)

for relative_path in "${config_paths[@]}"; do
    source_path="$HOME/.config/$relative_path"
    target_path="$destination/.config/$relative_path"

    if [[ ! -e "$source_path" && ! -L "$source_path" ]]; then
        printf 'Skipping missing: %s\n' "$source_path"
        continue
    fi

    mkdir -p "$target_path"

    if [[ -d "$source_path" ]]; then
        rsync -a "$source_path/" "$target_path/"
    else
        mkdir -p "$(dirname "$target_path")"
        cp -a "$source_path" "$target_path"
    fi
done

if [[ -d "$HOME/.local/bin" ]]; then
    rsync -a \
        "$HOME/.local/bin/" \
        "$destination/.local/bin/"
fi

pacman -Qqe \
    > "$repo/.local-import/manifests/packages-explicit.txt"

pacman -Qqm \
    > "$repo/.local-import/manifests/packages-foreign.txt" \
    2>/dev/null || true

systemctl --user list-unit-files \
    --state=enabled \
    --no-pager \
    > "$repo/.local-import/manifests/enabled-user-units.txt" \
    2>/dev/null || true

{
    echo "Imported: $(date --iso-8601=seconds)"
    echo

    echo "=== HYPRLAND ==="
    hyprctl version 2>&1 || true

    echo
    echo "=== KERNEL ==="
    uname -a

    echo
    echo "=== QUICKSHELL ==="
    qs --version 2>&1 || true

    echo
    echo "=== SWAYNC ==="
    swaync --version 2>&1 || true

    echo
    echo "=== SWAYOSD ==="
    swayosd-client --version 2>&1 || true
} > "$repo/.local-import/manifests/versions.txt"

echo
echo "Import complete."
echo "Nothing under .local-import will be committed."
