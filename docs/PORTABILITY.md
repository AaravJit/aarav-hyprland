# Portability architecture

The files under `config/` are renderable source files.

Machine-specific tokens:

- `__HOME__`
- `__MONITOR__`
- `__MONITOR_MODE__`
- `__WALLPAPER_DIR__`

The installer renders these tokens into a staging directory before
installing anything into the user's home directory.

Generated Matugen outputs are represented by tracked fallback files and
are regenerated during installation.
