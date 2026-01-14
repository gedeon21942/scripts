#!/usr/bin/env bash
# Shared helper functions for linutil scripts

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[linutil]${NC} $*"; }
err() { echo -e "${RED}[linutil][ERROR]${NC} $*" >&2; }

confirm() {
  # ask a yes/no question; returns 0 for yes
  local prompt="$1"
  while true; do
    read -r -p "$prompt [y/N]: " resp
    case "$resp" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]|"") return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

detect_pkg_mgr() {
  if command -v apt >/dev/null 2>&1; then
    echo "apt"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v zypper >/dev/null 2>&1; then
    echo "zypper"
  else
    echo "unknown"
  fi
}

run_as_sudo() {
  if [ "$EUID" -ne 0 ]; then
    sudo "$@"
  else
    "$@"
  fi
}
