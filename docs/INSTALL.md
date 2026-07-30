# Installation

Preview the installation:

```bash
./install.sh --dry-run
```

Install:

```bash
./install.sh
```

Check the installed profile:

```bash
./doctor.sh
```

Restore the most recent pre-install state:

```bash
./restore.sh latest
```

Uninstall by restoring the most recent pre-install state:

```bash
./uninstall.sh
```

The installer does not modify KDE, SDDM configuration, or graphics drivers.
