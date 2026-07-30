#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup_root="$HOME/.local/state/aarav-hyprland/install-backups"
selection="latest"
assume_yes=false

while (($#)); do
    case "$1" in
        --yes|-y) assume_yes=true; shift ;;
        -h|--help)
            echo "Usage: ./restore.sh [latest|BACKUP_PATH] [--yes]"
            exit 0
            ;;
        *) selection="$1"; shift ;;
    esac
done

[[ "$selection" == "latest" ]] \
    && backup="$backup_root/latest" \
    || backup="$selection"

backup="$(readlink -f "$backup" 2>/dev/null || true)"

if [[ -z "$backup" || ! -d "$backup" ]]; then
    echo "Backup not found." >&2
    exit 1
fi

python "$repo/tools/state-manager.py" verify --backup "$backup"

echo
echo "Backup selected:"
echo "  $backup"
echo
echo "This restores the files and service states captured before installation."

if ! $assume_yes; then
    read -r -p "Restore this backup? [y/N] " answer
    case "$answer" in
        y|Y|yes|YES) ;;
        *) echo "Restore cancelled."; exit 0 ;;
    esac
fi

python "$repo/tools/state-manager.py" restore \
    --home "$HOME" \
    --backup "$backup"

if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
fi

echo
echo "Restore complete."
echo "Packages installed by the preset were left installed."
echo "KDE, SDDM, and graphics drivers were not modified."
