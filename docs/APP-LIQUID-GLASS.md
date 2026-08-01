# Liquid Glass applications

The three most-used desktop applications are synchronized with the same Matugen palette as the shell.

## Vesktop / Discord

`liquid-glass-apps` writes Vesktop QuickCSS to:

```text
~/.config/vesktop/settings/quickCss.css
```

The main Liquid Glass wrapper preserves existing Vencord settings and enables `useQuickCss`. `launch-app discord` prefers native Vesktop with Wayland enabled and falls back to the official Discord client.

Vesktop is intentionally not installed by the repository's pacman-only package lists. On Arch, install the native AUR package once:

```bash
yay -S vesktop
```

## Spotify

The renderer writes a Spicetify theme to:

```text
~/.config/spicetify/Themes/AaravLiquidGlass
```

It selects the `Dynamic` color scheme and runs `spicetify apply`. The repository does not replace the user's Spotify executable or wrapper.

## Steam

The renderer writes a Millennium theme to:

```text
~/.steam/steam/steamui/skins/AaravLiquidGlass
```

Restart Steam after the first generation, then select **Aarav Liquid Glass** under Steam's Millennium theme settings. Later wallpaper changes rewrite the active theme's CSS; Steam may require its UI or client to be reloaded before every changed selector is visible.

## Rebuild

```bash
liquid-glass-apps --force
```

The normal wallpaper flow runs the application renderer automatically through `liquid-glass-apply`.
