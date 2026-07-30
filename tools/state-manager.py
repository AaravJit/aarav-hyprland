#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath
from typing import Any

REPLACE_ROOTS = (
    ".config/hypr",
    ".config/waybar",
    ".config/swaync",
    ".config/swayosd",
    ".config/matugen",
    ".config/quickshell/overview",
    ".config/fuzzel",
    ".config/kitty",
    ".config/uwsm",
    ".config/aarav-hyprland",
)

MERGE_ROOTS = (
    ".local/bin",
    ".config/systemd/user",
)


def exists(path: Path) -> bool:
    return path.exists() or path.is_symlink()


def safe_relative(value: str) -> str:
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"Unsafe path in manifest: {value}")
    return str(path)


def remove(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink(missing_ok=True)
    elif path.is_dir():
        shutil.rmtree(path)


def copy(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    if source.is_symlink():
        destination.symlink_to(os.readlink(source))
    elif source.is_dir():
        shutil.copytree(source, destination, symlinks=True)
    else:
        shutil.copy2(source, destination, follow_symlinks=False)


def managed_items(staging: Path) -> list[str]:
    result: list[str] = []

    for relative in REPLACE_ROOTS:
        if exists(staging / relative):
            result.append(relative)

    for root_name in MERGE_ROOTS:
        root = staging / root_name
        if not root.is_dir():
            continue
        for child in sorted(root.iterdir(), key=lambda item: item.name):
            result.append(str(PurePosixPath(root_name) / child.name))

    return list(dict.fromkeys(result))


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def checksums(root: Path) -> dict[str, Any]:
    result: dict[str, Any] = {}
    if not root.is_dir():
        return result

    for path in sorted(root.rglob("*")):
        relative = str(path.relative_to(root))
        if path.is_symlink():
            result[relative] = {
                "type": "symlink",
                "target": os.readlink(path),
            }
        elif path.is_file():
            result[relative] = {
                "type": "file",
                "sha256": sha256(path),
            }
    return result


def systemctl_state(action: str, unit: str) -> str:
    result = subprocess.run(
        ["systemctl", "--user", action, unit],
        check=False,
        capture_output=True,
        text=True,
    )
    output = result.stdout.strip() or result.stderr.strip()
    if output:
        return output.splitlines()[0]
    return "inactive" if action == "is-active" else "not-found"


def capture_services(units: list[str]) -> list[dict[str, str]]:
    return [
        {
            "unit": unit,
            "enabled": systemctl_state("is-enabled", unit),
            "active": systemctl_state("is-active", unit),
        }
        for unit in units
    ]


def systemctl(*arguments: str) -> None:
    result = subprocess.run(
        ["systemctl", "--user", *arguments],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        if message:
            print(
                f"[WARN] systemctl {' '.join(arguments)}: {message}",
                file=sys.stderr,
            )


def restore_services(backup: Path) -> None:
    path = backup / "service-states.json"
    if not path.is_file():
        return

    states = json.loads(path.read_text())
    systemctl("daemon-reload")

    enabled_states = {
        "enabled",
        "enabled-runtime",
        "linked",
        "linked-runtime",
        "alias",
    }

    for item in states:
        unit = item["unit"]
        previous = item["enabled"]
        systemctl("unmask", unit)

        if previous in enabled_states:
            systemctl("enable", unit)
        elif previous == "masked":
            systemctl("mask", unit)
        else:
            systemctl("disable", unit)

    for item in states:
        unit = item["unit"]
        if item["active"] == "active":
            systemctl("start", unit)
        else:
            systemctl("stop", unit)


def verify(backup: Path) -> None:
    manifest = backup / "manifest.json"
    checksum_file = backup / "checksums.json"
    payload = backup / "payload"

    if not manifest.is_file():
        raise RuntimeError(f"Missing backup manifest: {manifest}")
    if not checksum_file.is_file():
        raise RuntimeError(f"Missing backup checksums: {checksum_file}")

    expected = json.loads(checksum_file.read_text())
    current = checksums(payload)

    if current != expected:
        raise RuntimeError(
            "Backup checksum verification failed. Nothing was restored."
        )


def capture(
    home: Path,
    staging: Path,
    backup: Path,
    services: list[str],
) -> None:
    if backup.exists():
        raise RuntimeError(f"Backup already exists: {backup}")

    payload = backup / "payload"
    payload.mkdir(parents=True)

    items: list[dict[str, Any]] = []

    for relative in managed_items(staging):
        relative = safe_relative(relative)
        source = home / relative
        was_present = exists(source)

        items.append({"path": relative, "existed": was_present})

        if was_present:
            copy(source, payload / relative)

    manifest = {
        "version": 1,
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "home": str(home),
        "items": items,
    }

    (backup / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n"
    )
    (backup / "service-states.json").write_text(
        json.dumps(capture_services(services), indent=2) + "\n"
    )
    (backup / "checksums.json").write_text(
        json.dumps(checksums(payload), indent=2) + "\n"
    )
    print(backup)


def atomic_install(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = (
        destination.parent
        / f".{destination.name}.aarav-new-{os.getpid()}"
    )

    remove(temporary)
    copy(source, temporary)
    remove(destination)
    os.replace(temporary, destination)


def install(home: Path, staging: Path) -> None:
    for relative in managed_items(staging):
        relative = safe_relative(relative)
        atomic_install(staging / relative, home / relative)


def restore(
    home: Path,
    backup: Path,
    restore_service_state: bool,
) -> None:
    verify(backup)

    manifest = json.loads((backup / "manifest.json").read_text())
    payload = backup / "payload"

    for item in manifest["items"]:
        relative = safe_relative(str(item["path"]))
        destination = home / relative
        remove(destination)

        if item["existed"]:
            copy(payload / relative, destination)

    if restore_service_state:
        restore_services(backup)
    else:
        systemctl("daemon-reload")


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)

    capture_parser = sub.add_parser("capture")
    capture_parser.add_argument("--home", type=Path, required=True)
    capture_parser.add_argument("--staging", type=Path, required=True)
    capture_parser.add_argument("--backup", type=Path, required=True)
    capture_parser.add_argument("--service", action="append", default=[])

    install_parser = sub.add_parser("install")
    install_parser.add_argument("--home", type=Path, required=True)
    install_parser.add_argument("--staging", type=Path, required=True)

    restore_parser = sub.add_parser("restore")
    restore_parser.add_argument("--home", type=Path, required=True)
    restore_parser.add_argument("--backup", type=Path, required=True)
    restore_parser.add_argument("--no-services", action="store_true")

    verify_parser = sub.add_parser("verify")
    verify_parser.add_argument("--backup", type=Path, required=True)

    args = parser.parse_args()

    try:
        if args.command == "capture":
            capture(
                args.home.expanduser().resolve(),
                args.staging.resolve(),
                args.backup.expanduser().resolve(),
                args.service,
            )
        elif args.command == "install":
            install(
                args.home.expanduser().resolve(),
                args.staging.resolve(),
            )
        elif args.command == "restore":
            restore(
                args.home.expanduser().resolve(),
                args.backup.expanduser().resolve(),
                not args.no_services,
            )
        else:
            verify(args.backup.expanduser().resolve())
            print("Backup verification passed.")
    except Exception as error:
        print(f"state-manager: {error}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
