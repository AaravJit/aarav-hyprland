# Aarav Hyprland

A portable Hyprland desktop preset for Arch Linux systems.

This project packages a complete desktop configuration with automatic hardware detection, desktop and laptop profiles, NVIDIA/AMD/Intel support, dynamic Matugen colors, a cross-vendor GPU monitor, backups, restoration, and health checks.

The installer is designed to coexist with KDE Plasma and SDDM. It does not replace graphics drivers or remove an existing desktop environment.

---

## Features

- Hyprland with UWSM session management
- Desktop and laptop layouts
- NVIDIA, AMD, Intel, and generic GPU profiles
- Automatic monitor, battery, backlight, and touchpad detection
- Waybar with normal and Gaming Mode layouts
- Cross-vendor GPU status module
- Matugen wallpaper-based colors
- Hyprlock, Hypridle, Hyprpaper, and Hyprsunset
- SwayNC notification center
- SwayOSD volume and brightness overlays
- Fuzzel application launcher
- Quickshell workspace overview
- Automatic pre-install backups
- Restore and uninstall commands
- Installation doctor and render validation
- KDE Plasma and SDDM coexistence

## Supported systems

The installer currently targets:

- Arch Linux
- CachyOS
- Other Arch-based distributions using `pacman`

Supported GPU profiles:

- NVIDIA
- AMD
- Intel
- Generic

Supported device profiles:

- Desktop
- Laptop

Graphics drivers are **not** installed, removed, or replaced by this project. Your working graphics stack should already be installed.

---

# Installation

## 1. Install the bootstrap tools

You only need Git and Python before cloning the repository:

```bash
sudo pacman -S --needed git python
```

The installer handles the rest of the required packages.

## 2. Clone the repository

```bash
git clone https://github.com/AaravJit/aarav-hyprland.git
cd aarav-hyprland
```

Do not run the installer with `sudo`. It will ask for your password only when `pacman` needs to install packages.

## 3. Run a dry run first

```bash
./install.sh --dry-run
```

A dry run:

1. Detects your hardware.
2. Selects a desktop or laptop profile.
3. Detects the GPU vendor.
4. Renders the complete configuration into a temporary directory.
5. Downloads the pinned Quickshell overview source.
6. Validates Lua, JSON, TOML, scripts, GPU settings, and profile behavior.
7. Shows the installation plan.
8. Makes no changes to your system.

A successful dry run ends with:

```text
RESULT: VALID

DRY RUN COMPLETE
The rendered installation passed validation.
```

Do not continue with a real installation if the dry run reports a failure.

## 4. Install the preset

```bash
./install.sh
```

Review the installation plan and enter `y` when prompted.

The installer will:

1. Detect your hardware.
2. Render the correct profile.
3. Validate the rendered configuration.
4. Install missing official Arch packages.
5. Create a full pre-install backup.
6. Install the rendered files.
7. Enable the required user services.
8. Generate the initial Matugen color palette.
9. Reload Hyprland when it is already running.
10. Run the installation doctor.

## 5. Select Hyprland at login

Log out and select:

```text
Hyprland (uwsm-managed)
```

from the SDDM session menu.

KDE Plasma remains available as a separate session.

## 6. Check the installation

After logging into Hyprland:

```bash
cd ~/aarav-hyprland
./doctor.sh
```

A clean installation should end with:

```text
RESULT: HEALTHY
```

Warnings are displayed separately. A warning does not always mean the desktop is broken; for example, runtime checks are skipped when the doctor is run outside a Hyprland session.

---

# Installer options

```text
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
```

## Common examples

### Force a laptop profile

```bash
./install.sh --profile laptop
```

### Force an AMD profile

```bash
./install.sh --gpu amd
```

### Force an Intel laptop profile

```bash
./install.sh --profile laptop --gpu intel
```

### Force an NVIDIA desktop profile

```bash
./install.sh --profile desktop --gpu nvidia
```

### Set a specific monitor

```bash
./install.sh --monitor eDP-1
```

### Set a specific monitor mode

```bash
./install.sh \
  --monitor eDP-1 \
  --mode 2880x1800@120 \
  --scale 1.5
```

### Use a specific wallpaper

```bash
./install.sh --wallpaper ~/Pictures/wallpaper.png
```

### Use a wallpaper directory

```bash
./install.sh --wallpaper-dir ~/Pictures/Wallpapers
```

### Skip package installation

```bash
./install.sh --skip-packages
```

This is intended for testing or systems where all dependencies were installed manually. The doctor may report missing commands afterward.

### Non-interactive installation

```bash
./install.sh --yes
```

Use this only after a successful dry run.

---

# Hybrid GPU systems

Some laptops expose more than one GPU vendor, such as Intel plus NVIDIA or AMD plus NVIDIA.

When multiple vendors are detected, the installer asks which GPU should drive Hyprland.

You can select it manually:

```bash
./install.sh --gpu intel
```

or:

```bash
./install.sh --gpu nvidia
```

Choose the GPU used by your display session. The installer does not configure PRIME, GPU offloading, kernel modules, or graphics drivers.

---

# Updating

Pull the latest repository changes:

```bash
cd ~/aarav-hyprland
git pull
```

Always preview an update:

```bash
./install.sh --dry-run
```

Then apply it:

```bash
./install.sh
```

Every successful installation creates a new pre-install backup.

---

# Backups

Installer backups are stored in:

```text
~/.local/state/aarav-hyprland/install-backups/
```

The latest completed backup is available through:

```text
~/.local/state/aarav-hyprland/install-backups/latest
```

See the current latest backup:

```bash
readlink -f \
  ~/.local/state/aarav-hyprland/install-backups/latest
```

Backups include:

- Files that the installer replaces
- Files that the installer merges into managed locations
- Previous user-service enable states
- Previous user-service active states
- Hardware detection results
- Rendered machine metadata
- Repository commit information
- SHA-256 checksums for backup verification

---

# Restoring the previous configuration

Restore the state from immediately before the latest installation:

```bash
./restore.sh latest
```

Skip the confirmation prompt:

```bash
./restore.sh latest --yes
```

Restore a specific backup:

```bash
./restore.sh \
  ~/.local/state/aarav-hyprland/install-backups/2026-07-29-230000
```

The restore command verifies backup checksums before changing files.

Installed packages are intentionally left installed.

---

# Uninstalling

The uninstall command restores the pre-install state from the latest completed backup:

```bash
./uninstall.sh
```

This removes the managed preset files by restoring whatever existed before the installation.

The uninstall command does not:

- Remove packages
- Remove graphics drivers
- Remove KDE Plasma
- Change SDDM configuration

---

# Doctor

Run the normal health check:

```bash
./doctor.sh
```

Treat warnings as failures:

```bash
./doctor.sh --strict
```

Check a different home directory:

```bash
./doctor.sh --home /home/example
```

The doctor checks:

- Machine metadata
- Required commands
- Required configuration files
- Lua syntax
- JSON and TOML validity
- Unresolved render tokens
- Wallpaper link status
- Desktop or laptop profile behavior
- GPU-specific UWSM environment
- Hyprland service isolation
- Runtime Hyprland configuration errors
- Installer backup status

---

# What the installer changes

The installer manages the following locations:

```text
~/.config/hypr
~/.config/waybar
~/.config/swaync
~/.config/swayosd
~/.config/matugen
~/.config/quickshell/overview
~/.config/fuzzel
~/.config/kitty
~/.config/uwsm
~/.config/aarav-hyprland
~/.config/systemd/user
~/.local/bin
```

Before replacing managed files, the installer records their existing state in a backup.

Files under `.local/bin` and `.config/systemd/user` are installed item by item so unrelated user files are preserved.

---

# What the installer does not change

The installer does not intentionally modify:

- KDE Plasma configuration
- SDDM configuration
- Bootloader configuration
- Graphics drivers
- Kernel modules
- PRIME or GPU-offloading configuration
- System-wide shell configuration
- Personal documents
- Browser profiles
- Steam libraries

---

# Default keybindings

| Keybinding | Action |
|---|---|
| `Super + Space` | Open Fuzzel |
| `Super + T` | Open Kitty |
| `Super + E` | Open Dolphin |
| `Super + B` | Open Zen Browser |
| `Super + S` | Open Spotify |
| `Super + D` | Open Discord |
| `Super + G` | Open Steam |
| `Super + Shift + G` | Open Heroic |
| `Super + Q` | Close active window |
| `Super + F` | Fullscreen |
| `Super + Shift + F` | Maximize |
| `Super + Shift + Space` | Toggle floating |
| `Super + R` | Open scratchpad |
| `Super + Shift + R` | Send window to scratchpad |
| `Super + V` | Clipboard history |
| `Super + Z` | Open SwayNC |
| `Super + A` | Open audio controls |
| `Super + W` | Change wallpaper |
| `Super + Tab` | Workspace overview |
| `Super + Ctrl + G` | Toggle Gaming Mode |
| `Super + Ctrl + R` | Safe configuration reload |
| `Super + Esc` | Open power menu |
| `Super + L` | Lock screen |
| `Super + Shift + Esc` | Log out |
| `Super + 1–5` | Switch workspace |
| `Super + Shift + 1–5` | Move window to workspace |

Media, volume, mute, and brightness keys are supported when the hardware exposes them.

---

# Gaming Mode

Toggle Gaming Mode with:

```text
Super + Ctrl + G
```

Gaming Mode temporarily:

- Removes gaps and borders
- Disables animations
- Disables blur and shadows
- Stops Hypridle
- Inhibits notifications
- Switches Waybar to its compact layout

Running the command again restores the previous desktop state.

---

# Repository layout

```text
aarav-hyprland/
├── config/                  Portable configuration source
├── scripts/                 Installed user scripts
├── systemd/user/            User units and session guards
├── packages/                Package manifests
├── profiles/gpu/            GPU-specific UWSM environments
├── tools/
│   ├── detect-hardware.py
│   ├── prepare-portable-source.py
│   ├── render-profile.py
│   ├── validate-render.py
│   └── state-manager.py
├── tests/fixtures/          Fake hardware profiles
├── docs/
├── install.sh
├── doctor.sh
├── restore.sh
└── uninstall.sh
```

---

# Testing the renderer

## Current machine

```bash
./install.sh --dry-run
```

## AMD laptop fixture

```bash
./install.sh \
  --dry-run \
  --hardware-json tests/fixtures/amd-laptop.json \
  --profile laptop \
  --gpu amd
```

## Intel laptop fixture

```bash
./install.sh \
  --dry-run \
  --hardware-json tests/fixtures/intel-laptop.json \
  --profile laptop \
  --gpu intel
```

All three should end with:

```text
RESULT: VALID
```

and:

```text
DRY RUN COMPLETE
```

---

# Troubleshooting

## Multiple GPUs were detected

Rerun with an explicit vendor:

```bash
./install.sh --gpu intel
```

or:

```bash
./install.sh --gpu nvidia
```

## The wrong monitor was selected

List Hyprland monitors:

```bash
hyprctl monitors
```

Then rerun:

```bash
./install.sh --monitor eDP-1
```

## The display scale is wrong

Rerun with an explicit scale:

```bash
./install.sh --scale 1.5
```

## The display mode is wrong

```bash
./install.sh \
  --monitor DP-1 \
  --mode 3440x1440@144 \
  --scale 1
```

## Quickshell overview could not download

Confirm that GitHub is reachable and rerun the installer.

The initial installation normally requires internet access because the pinned Quickshell overview source is downloaded before validation.

## The installation failed after creating a backup

The installer automatically attempts a rollback.

You can also restore manually:

```bash
./restore.sh latest
```

## The doctor reports missing packages

Run the installer again without `--skip-packages`:

```bash
./install.sh
```

## Hyprland reports configuration errors

Run:

```bash
hyprctl configerrors
```

Then restore the latest pre-install state when necessary:

```bash
./restore.sh latest
```

## KDE still appears in SDDM

That is expected. The project installs Hyprland alongside KDE rather than replacing it.

Choose `Hyprland (uwsm-managed)` from the session menu.

---

# Safety notes

- Run the dry run before every installation or update.
- Do not run `install.sh` with `sudo`.
- Keep the repository until you no longer need restore and update commands.
- Verify that `doctor.sh` is healthy before deleting old backups.
- Test the laptop profile on actual hardware before treating every laptop model as fully verified.
- Keep graphics-driver configuration outside this project.

---

# License

MIT License. See [`LICENSE`](LICENSE).
