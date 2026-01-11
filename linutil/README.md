
linutil — lightweight Linux utilities collection (Arch-ready)

This is a small, safe scaffolding for a "linutil" collection inspired by Chris Titus' utilities. It provides a modular place to add install scripts, system tweaks, and helpers. The scripts are intentionally conservative: they prompt before making system changes.

Target distro: Arch Linux (pacman). The `install.sh` will detect your package manager; the example package list in `example-packages.txt` is tailored for Arch. AUR packages are not installed by default — use an AUR helper such as `yay` or `paru` if you want AUR packages.

Files:
- install.sh — interactive entrypoint; detects package manager and offers tasks.
- utils.sh — helper functions used by other scripts.
- system-info.sh — collects basic system information.
- example-packages.txt — suggested packages to install (editable).

Usage:
1. Inspect scripts and edit package lists to match your distro.
2. Make scripts executable: `chmod +x *.sh`
3. Run interactively: `sudo ./install.sh` or `./install.sh` (it will prompt for sudo when needed).

Contributing:
Add more scripts to this folder (e.g., nvidia.sh, dotfiles.sh). Keep actions explicit and require confirmation for destructive operations.
