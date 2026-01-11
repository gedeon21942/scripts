#!/usr/bin/env bash
# Interactive installer / entrypoint for linutil

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/utils.sh"

PKG_MGR=$(detect_pkg_mgr)
log "Detected package manager: $PKG_MGR"

show_menu() {
  cat <<'EOF'
linutil - tasks
1) Show system info
2) Arch
3) Apply safe tweaks (example)
4) Open package list for editing
5) Exit
6) Install example packages
EOF
}

arch_menu() {
  while true; do
    cat <<'EOF'
Arch - tasks
1) Arch server
2) Back
EOF
    read -r -p "Select an option (1-2): " aopt
    case "$aopt" in
      1) arch_server ;; 
      2) return 0 ;;
      *) echo "Invalid choice." ;;
    esac
  done
}

arch_server() {
  log "Arch server selected. Launching arch-server.sh (prompts required)."
  bash "$DIR/arch-server.sh"
}

install_example_packages() {
  local list_file="$DIR/example-packages.txt"
  if [ ! -f "$list_file" ]; then
    err "Package list $list_file not found."
    return 1
  fi

  log "Packages listed in $list_file:"
  sed -n '1,200p' "$list_file" | nl -ba

  if ! confirm "Proceed to install these packages using $PKG_MGR?"; then
    log "Aborted package installation."
    return 0
  fi

  case "$PKG_MGR" in
    apt)
      run_as_sudo apt update
      xargs -a "$list_file" -r sudo apt install -y
      ;;
    pacman)
      run_as_sudo pacman -Sy --noconfirm
      xargs -a "$list_file" -r sudo pacman -S --noconfirm
      ;;
    dnf)
      run_as_sudo dnf install -y $(tr '\n' ' ' < "$list_file")
      ;;
    zypper)
      run_as_sudo zypper install -y $(tr '\n' ' ' < "$list_file")
      ;;
    *)
      err "Unsupported package manager: $PKG_MGR. Open $list_file and install manually."
      return 1
      ;;
  esac

  log "Package installation finished."
}

apply_tweaks() {
  log "This is an example tweaks function. It will only show actions."
  echo "Example: enable /etc/sysctl.d/99-linutil.conf with vm.swappiness=10"
  if confirm "Write a sample sysctl file to set swappiness to 10?"; then
    local tmp="$DIR/99-linutil-sysctl.conf"
    echo "vm.swappiness=10" > "$tmp"
    log "Created $tmp (not yet moved to /etc/sysctl.d)."
    if confirm "Move it to /etc/sysctl.d/ and apply (requires sudo)?"; then
      run_as_sudo mv "$tmp" /etc/sysctl.d/99-linutil-sysctl.conf
      run_as_sudo sysctl --system || true
      log "Applied sysctl settings."
    else
      log "Left file in $tmp. You can move it manually if desired."
    fi
  fi
}

open_package_list() {
  ${EDITOR:-vi} "$DIR/example-packages.txt"
}

main() {
  while true; do
    show_menu
    read -r -p "Select an option (1-6): " opt
    case "$opt" in
      1) bash "$DIR/system-info.sh" ;;
      2) arch_menu ;;
      3) apply_tweaks ;;
      4) open_package_list ;;
      5) log "Exiting."; exit 0 ;;
      6) install_example_packages ;;
      *) echo "Invalid choice." ;;
    esac
  done
}

main "$@"
