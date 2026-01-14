#!/usr/bin/env bash
# Interactive installer / entrypoint for linutil

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$DIR/utils.sh"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

PKG_MGR=$(detect_pkg_mgr)
log "Detected package manager: $PKG_MGR"

show_banner() {
  clear
  echo -e "${CYAN}"
  cat << 'EOF'
██╗     ██╗███╗   ██╗██╗   ██╗████████╗██╗██╗
██║     ██║████╗  ██║██║   ██║╚══██╔══╝██║██║
██║     ██║██╔██╗ ██║██║   ██║   ██║   ██║██║
██║     ██║██║╚██╗██║██║   ██║   ██║   ██║██║
███████╗██║██║ ╚████║╚██████╔╝   ██║   ██║███████╗
╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚═╝╚══════╝
EOF
  echo -e "${WHITE}Linux Utility Tool - Interactive Installer${NC}"
  echo -e "${YELLOW}============================================${NC}"
  echo ""
}

show_menu() {
  show_banner
  echo -e "${GREEN}Available Tasks:${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${WHITE}1)${NC} Show system information"
  echo -e "${WHITE}2)${NC} Arch Linux tasks"
  echo -e "${WHITE}3)${NC} Apply safe system tweaks"
  echo -e "${WHITE}4)${NC} Edit package list"
  echo -e "${WHITE}5)${NC} Install example packages"
  echo -e "${WHITE}6)${NC} Exit"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

arch_menu() {
  while true; do
    show_banner
    echo -e "${GREEN}Arch Linux Tasks:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}1)${NC} Arch server setup"
    echo -e "${WHITE}2)${NC} Back to main menu"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -r -p "$(echo -e "${YELLOW}Select an option (1-2): ${NC}")" aopt
    case "$aopt" in
      1) arch_server ;; 
      2) return 0 ;;
      *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac
  done
}

arch_server() {
  echo -e "${MAGENTA}🚀 Launching Arch server setup...${NC}"
  log "Arch server selected. Launching arch-server.sh (prompts required)."
  bash "$DIR/arch-server.sh"
}

install_example_packages() {
  local list_file="$DIR/example-packages.txt"
  if [ ! -f "$list_file" ]; then
    err "Package list $list_file not found."
    return 1
  fi

  echo -e "${CYAN}📦 Packages to be installed:${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  sed -n '1,200p' "$list_file" | nl -ba | sed 's/^/  /'
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if ! confirm "$(echo -e "${YELLOW}Proceed to install these packages using $PKG_MGR?${NC}")"; then
    log "Package installation aborted."
    return 0
  fi

  echo -e "${MAGENTA}🔄 Updating package database...${NC}"
  case "$PKG_MGR" in
    apt)
      run_as_sudo apt update
      echo -e "${MAGENTA}📥 Installing packages...${NC}"
      xargs -a "$list_file" -r sudo apt install -y
      ;;
    pacman)
      run_as_sudo pacman -Sy --noconfirm
      echo -e "${MAGENTA}📥 Installing packages...${NC}"
      xargs -a "$list_file" -r sudo pacman -S --noconfirm
      ;;
    dnf)
      echo -e "${MAGENTA}📥 Installing packages...${NC}"
      run_as_sudo dnf install -y $(tr '\n' ' ' < "$list_file")
      ;;
    zypper)
      echo -e "${MAGENTA}📥 Installing packages...${NC}"
      run_as_sudo zypper install -y $(tr '\n' ' ' < "$list_file")
      ;;
    *)
      err "Unsupported package manager: $PKG_MGR. Open $list_file and install manually."
      return 1
      ;;
  esac

  echo -e "${GREEN}✅ Package installation completed!${NC}"
}

apply_tweaks() {
  echo -e "${CYAN}🔧 System Tweaks${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${WHITE}This is an example tweaks function. It will only show actions.${NC}"
  echo -e "${YELLOW}Example: Enable /etc/sysctl.d/99-linutil.conf with vm.swappiness=10${NC}"
  echo ""

  if confirm "$(echo -e "${YELLOW}Write a sample sysctl file to set swappiness to 10?${NC}")"; then
    local tmp="$DIR/99-linutil-sysctl.conf"
    echo "vm.swappiness=10" > "$tmp"
    echo -e "${GREEN}✅ Created $tmp (not yet moved to /etc/sysctl.d)${NC}"
    if confirm "$(echo -e "${YELLOW}Move it to /etc/sysctl.d/ and apply (requires sudo)?${NC}")"; then
      run_as_sudo mv "$tmp" /etc/sysctl.d/99-linutil-sysctl.conf
      run_as_sudo sysctl --system || true
      echo -e "${GREEN}✅ Applied sysctl settings${NC}"
    else
      echo -e "${BLUE}ℹ️  Left file in $tmp. You can move it manually if desired.${NC}"
    fi
  fi
}

open_package_list() {
  echo -e "${CYAN}📝 Opening package list for editing...${NC}"
  ${EDITOR:-vi} "$DIR/example-packages.txt"
}

main() {
  show_banner
  while true; do
    show_menu
    read -r -p "$(echo -e "${YELLOW}Select an option (1-6): ${NC}")" opt
    case "$opt" in
      1) bash "$DIR/system-info.sh" ;;
      2) arch_menu ;;
      3) apply_tweaks ;;
      4) open_package_list ;;
      5) log "Exiting."; exit 0 ;;
      6) install_example_packages ;;
      *) echo -e "${RED}Invalid choice. Please try again.${NC}" ;;
    esac
  done
}

main "$@"
