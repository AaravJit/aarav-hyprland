#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from settings_apply import apply_components, apply_launcher, open_panel, retheme_current
from settings_core import (
    DEFAULTS,
    load_settings,
    normalize,
    print_json,
    save_settings,
    theme_arguments,
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage Aarav Hyprland user settings")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("get-json")
    commands.add_parser("open")

    set_parser = commands.add_parser("set-json")
    set_parser.add_argument("payload")

    apply_parser = commands.add_parser("apply")
    apply_parser.add_argument(
        "--component", choices=["all", "hyprland", "launcher"], default="all"
    )
    apply_parser.add_argument("--quiet", action="store_true")

    reset_parser = commands.add_parser("reset")
    reset_parser.add_argument("--quiet", action="store_true")

    roots_parser = commands.add_parser("wallpaper-roots")
    roots_parser.add_argument("--null", action="store_true")
    roots_parser.add_argument("--all", action="store_true")

    theme_parser = commands.add_parser("theme-args")
    theme_parser.add_argument("--null", action="store_true")
    commands.add_parser("retheme")

    args = parser.parse_args()
    settings = load_settings()

    try:
        if args.command == "get-json":
            print_json(settings)
        elif args.command == "open":
            open_panel(settings)
        elif args.command == "set-json":
            payload = json.loads(args.payload)
            if isinstance(payload, dict) and isinstance(payload.get("settings"), dict):
                payload = payload["settings"]
            old_theme = {
                key: settings["wallpaper"][key]
                for key in ("mode", "scheme", "source_color_index")
            }
            settings = normalize(payload)
            save_settings(settings)
            apply_components(settings, "all")
            new_theme = {
                key: settings["wallpaper"][key]
                for key in ("mode", "scheme", "source_color_index")
            }
            if new_theme != old_theme:
                retheme_current(settings)
                apply_launcher(settings)
            print_json(settings)
        elif args.command == "apply":
            save_settings(settings)
            apply_components(settings, args.component)
            if not args.quiet:
                print_json(settings)
        elif args.command == "reset":
            settings = normalize(DEFAULTS)
            save_settings(settings)
            apply_components(settings, "all")
            retheme_current(settings)
            apply_launcher(settings)
            if not args.quiet:
                print_json(settings)
        elif args.command == "wallpaper-roots":
            roots = settings["wallpaper"]["directories"]
            if not args.all:
                roots = [path for path in roots if Path(path).is_dir()]
            separator = "\0" if args.null else "\n"
            sys.stdout.write(separator.join(roots) + (separator if roots else ""))
        elif args.command == "theme-args":
            values = theme_arguments(settings)
            separator = "\0" if args.null else "\n"
            sys.stdout.write(separator.join(values) + (separator if values else ""))
        elif args.command == "retheme":
            retheme_current(settings)
            apply_launcher(settings)
            print_json(settings)
    except (json.JSONDecodeError, RuntimeError, OSError) as error:
        print(f"aarav-settings: {error}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
