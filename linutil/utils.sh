#!/usr/bin/env bash
# Shared helper functions for linutil scripts

set -euo pipefail

log() { echo -e "[linutil] $*"; }
err() { echo -e "[linutil][ERROR] $*" >&2; }

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
