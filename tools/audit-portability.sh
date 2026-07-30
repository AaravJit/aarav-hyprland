#!/usr/bin/env bash
set -euo pipefail

repo="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

root="$repo/.local-import/home"

if [[ ! -d "$root" ]]; then
    echo "Run tools/import-current.sh first."
    exit 1
fi

grep_matches() {
    local pattern="$1"
    local output_file="$2"

    grep \
        -RInI \
        -E "$pattern" \
        --exclude-dir=.git \
        --exclude='*.png' \
        --exclude='*.jpg' \
        --exclude='*.jpeg' \
        --exclude='*.webp' \
        --exclude='*.gif' \
        --exclude='README.md' \
        --exclude='*.before-*' \
        --exclude='*.stage*' \
        --exclude='*.baseline-*' \
        --exclude='*.working' \
        "$root" \
        > "$output_file" \
        2>/dev/null || true
}

report_matches() {
    local heading="$1"
    local pattern="$2"
    local limit="${3:-60}"
    local temporary

    temporary="$(mktemp)"

    grep_matches "$pattern" "$temporary"

    echo
    echo "========================================"
    echo "$heading"
    echo "========================================"
    echo "Matches: $(wc -l < "$temporary")"

    head -n "$limit" "$temporary"

    rm -f "$temporary"
}

echo "========================================"
echo "PORTABILITY AUDIT"
echo "========================================"

echo
echo "Imported root:"
echo "$root"

report_matches \
    "HARDCODED HOME DIRECTORIES" \
    '/home/[A-Za-z0-9._-]+'

report_matches \
    "USERNAME REFERENCES" \
    'aarav'

report_matches \
    "HARDCODED MONITOR NAMES" \
    '(^|[^A-Za-z])(DP-[0-9]+|HDMI-A-[0-9]+|eDP-[0-9]+)'

report_matches \
    "RESOLUTION OR REFRESH ASSUMPTIONS" \
    '3440x1440|2560x[0-9]+|1920x1080|@[0-9]{2,3}([.][0-9]+)?'

report_matches \
    "NVIDIA-SPECIFIC LOGIC" \
    'nvidia-smi|NVIDIA|__GL_|GBM_BACKEND|NVK|nvidia_drm'

report_matches \
    "BATTERY, BACKLIGHT, OR LAPTOP LOGIC" \
    'BAT[0-9]+|/sys/class/backlight|brightnessctl|backlight|touchpad'

report_matches \
    "POTENTIAL SECRET-LIKE ASSIGNMENTS" \
    '(token|api[_-]?key|client[_-]?secret|authorization)[[:space:]]*[:=]' \
    30

echo
echo "========================================"
echo "IMPORT SIZE"
echo "========================================"

du -sh "$root"

echo
echo "========================================"
echo "GIT SAFETY"
echo "========================================"

cd "$repo"

if git check-ignore -q .local-import; then
    echo "[PASS] .local-import is ignored by Git."
else
    echo "[FAIL] .local-import is not ignored."
    exit 1
fi

if git status --short --ignored |
    grep -q '^!! .local-import/'
then
    echo "[PASS] Git explicitly reports the import as ignored."
else
    echo "[WARN] Could not confirm ignored import through git status."
fi
