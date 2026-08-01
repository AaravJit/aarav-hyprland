# Liquid Glass desktop

The Liquid Glass layer is a wallpaper-aware design system for every shell surface managed by this repository. It keeps the existing Matugen workflow, but routes one generated Material palette through a shared renderer so the desktop cannot drift into several unrelated themes.

## Covered surfaces

- Hyprland window geometry, blur, shadows, borders, and motion
- Waybar and its tooltips, workspaces, status pills, and gaming indicator
- Fuzzel application, clipboard, and wallpaper pickers
- SwayNC notifications, control center, media, volume, and quick settings
- SwayOSD volume and brightness overlays
- nwg-bar power menu
- Hyprlock clock, authentication material, and password field
- Quickshell overview and Aarav Settings
- Kitty colors, opacity, and spacing

Third-party application content remains controlled by each application's GTK, Qt, browser, or in-app theme. Hyprland still gives those windows the shared rounded geometry, opacity, shadow, and blur treatment.

## Dynamic wallpaper colors

`matugen` writes the current wallpaper palette to:

```text
~/.config/aarav-hyprland/liquid-glass-colors.json
```

Its post-hook runs:

```bash
~/.local/bin/liquid-glass-apply --refresh --quiet
```

Changing the wallpaper with `Super + W` therefore updates the compositor accents, bar, launchers, notifications, OSD, power menu, lock screen, overview, settings panel, and terminal together.

## Geometry

Normal mode uses rounded windows, floating material surfaces, thin highlights, deeper soft shadows, and stronger compositor blur. The settings panel clamps Hyprland-controlled rounding to the wrapper's supported maximum of 20.

Gaming Mode remains intentionally separate. It still disables gaps, borders, blur, shadows, rounding, and animations for the performance-focused layout.

## Commands

Rebuild every surface from the current palette and saved settings:

```bash
liquid-glass-apply --force --refresh
```

Apply only when the palette or settings changed:

```bash
liquid-glass-apply --refresh
```

Inspect the generated palette:

```bash
cat ~/.config/aarav-hyprland/liquid-glass-colors.json
```

The renderer stores its digest at:

```text
~/.local/state/aarav-hyprland/liquid-glass-state.json
```

## Recovery

The regular installer creates a full backup before deployment. Restore the newest backup with:

```bash
~/Projects/aarav-hyprland/restore.sh latest
```

The normal `doctor.sh --strict` and portable render validation remain the authoritative health checks after installation.
