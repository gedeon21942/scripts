#!/usr/bin/env bash
# Arch server installer wrapper

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/utils.sh"

PKG_MGR=$(detect_pkg_mgr)

ASSUME_YES=0
DRY_RUN=0
LIST_FILE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [--yes|-y] [--dry-run] [--file <path>]

Options:
  --yes, -y       Assume yes to prompts and run non-interactively
  --dry-run       Show what would be installed without executing
  --file <path>   Use a custom package list file
  --help          Show this help
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes|-y) ASSUME_YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --file|-f)
      shift
      LIST_FILE="$1"
      shift
      ;;
    --file=*) LIST_FILE="${1#*=}"; shift ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

if [ -z "$LIST_FILE" ]; then
  if [ -f "$DIR/example-packages-arch-server.txt" ]; then
    LIST_FILE="$DIR/example-packages-arch-server.txt"
  else
    LIST_FILE="$DIR/example-packages.txt"
  fi
fi

if [ ! -f "$LIST_FILE" ]; then
  err "Package list $LIST_FILE not found."
  exit 1
fi

log "Arch server - packages listed in $LIST_FILE:"
sed -n '1,200p' "$LIST_FILE" | nl -ba

if [ "$DRY_RUN" -eq 1 ]; then
  log "DRY RUN: not performing any installations."
  case "$PKG_MGR" in
    pacman)
      echo "Would run: pacman -Sy --noconfirm";
      echo "Would run: pacman -S --noconfirm <packages from $LIST_FILE>";
      ;;
    apt)
      echo "Would run: apt update";
      echo "Would run: apt install -y <packages from $LIST_FILE>";
      ;;
    dnf|zypper)
      echo "Would run: $PKG_MGR install -y <packages from $LIST_FILE>";
      ;;
    *) echo "Would prompt to install packages manually." ;;
  esac
  exit 0
fi

if [ "$ASSUME_YES" -eq 0 ]; then
  if ! confirm "Proceed to install these packages for Arch server using $PKG_MGR?"; then
    log "Aborted Arch server package installation."
    exit 0
  fi
fi

log "Installing packages using $PKG_MGR..."
case "$PKG_MGR" in
  pacman)
    if [ "$DRY_RUN" -eq 1 ]; then
      log "DRY RUN: pacman -Sy --noconfirm";
      log "DRY RUN: pacman -S --noconfirm (packages from $LIST_FILE)";
    else
      run_as_sudo pacman -Sy --noconfirm
      xargs -a "$LIST_FILE" -r sudo pacman -S --noconfirm
    fi
    ;;
  apt)
    if [ "$DRY_RUN" -eq 1 ]; then
      log "DRY RUN: apt update";
      log "DRY RUN: apt install -y (packages from $LIST_FILE)";
    else
      run_as_sudo apt update
      xargs -a "$LIST_FILE" -r sudo apt install -y
    fi
    ;;
  dnf)
    if [ "$DRY_RUN" -eq 1 ]; then
      log "DRY RUN: dnf install -y (packages from $LIST_FILE)";
    else
      run_as_sudo dnf install -y $(tr '\n' ' ' < "$LIST_FILE")
    fi
    ;;
  zypper)
    if [ "$DRY_RUN" -eq 1 ]; then
      log "DRY RUN: zypper install -y (packages from $LIST_FILE)";
    else
      run_as_sudo zypper install -y $(tr '\n' ' ' < "$LIST_FILE")
    fi
    ;;
  *)
    err "Unsupported package manager: $PKG_MGR. Open $LIST_FILE and install manually."
    exit 1
    ;;
esac

log "Package installation finished."

# Optionally enable common services if systemctl is available
if command -v systemctl >/dev/null 2>&1; then
  for svc in sshd NetworkManager docker; do
    if systemctl list-unit-files --type=service | grep -qw "${svc}.service"; then
      if [ "$ASSUME_YES" -eq 1 ] || confirm "Enable and start ${svc}.service?"; then
        if [ "$DRY_RUN" -eq 1 ]; then
          log "DRY RUN: systemctl enable --now ${svc}.service"
        else
          run_as_sudo systemctl enable --now "${svc}.service" || true
          log "Enabled and started ${svc}.service (if present)."
        fi
      fi
    fi
  done
fi

exit 0
