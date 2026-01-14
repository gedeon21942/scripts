#!/usr/bin/env bash
# Arch Linux Server Installer

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

# Global variables
TARGET_DISK=""
HOSTNAME=""
USERNAME=""
PASSWORD=""
TIMEZONE="America/Detroit"
LOCALE="en_US.UTF-8"

show_installer_banner() {
  clear
  echo -e "${CYAN}"
  cat << 'EOF'
 █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
███████║██████╔╝██║     ███████║    ███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
██║  ██║██║  ██║╚██████╗██║  ██║    ███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
EOF
  echo -e "${WHITE}Arch Linux Server Installation Script${NC}"
  echo -e "${YELLOW}=========================================${NC}"
  echo ""
  echo -e "${RED}⚠️  WARNING: This script will COMPLETELY WIPE the selected drive!${NC}"
  echo -e "${RED}   Make sure you have backups of any important data.${NC}"
  echo -e "${YELLOW}   Only run this on a fresh installation or virtual machine.${NC}"
  echo ""
}

get_disk_info() {
  echo -e "${CYAN}💽 Available Disks:${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  lsblk -d -o NAME,SIZE,MODEL | grep -v "loop\|sr\|rom" | while read -r line; do
    echo -e "${WHITE}  $line${NC}"
  done
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

select_target_disk() {
  while true; do
    echo -e "${YELLOW}Enter the target disk (e.g., /dev/sda, /dev/nvme0n1, /dev/vda):${NC}"
    read -r -p "Disk: " TARGET_DISK

    if [ ! -b "$TARGET_DISK" ]; then
      echo -e "${RED}❌ Error: $TARGET_DISK is not a valid block device${NC}"
      continue
    fi

    # Check if disk is mounted
    if mount | grep -q "^$TARGET_DISK"; then
      echo -e "${RED}❌ Error: $TARGET_DISK appears to be mounted. Unmount it first.${NC}"
      continue
    fi

    echo -e "${RED}⚠️  WARNING: All data on $TARGET_DISK will be destroyed!${NC}"
    echo -e "${WHITE}Disk info:${NC}"
    lsblk "$TARGET_DISK" -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINT

    if confirm "$(echo -e "${YELLOW}Are you sure you want to use $TARGET_DISK? This will erase all data!${NC}")"; then
      break
    fi
  done
}

get_hostname() {
  while true; do
    read -r -p "$(echo -e "${YELLOW}Enter hostname: ${NC}")" HOSTNAME
    if [[ "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]] && [ ${#HOSTNAME} -le 63 ]; then
      break
    else
      echo -e "${RED}❌ Invalid hostname. Use only letters, numbers, and hyphens. Must start/end with alphanumeric.${NC}"
    fi
  done
}

get_username() {
  while true; do
    read -r -p "$(echo -e "${YELLOW}Enter username: ${NC}")" USERNAME
    if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] && [ ${#USERNAME} -ge 1 ] && [ ${#USERNAME} -le 32 ]; then
      break
    else
      echo -e "${RED}❌ Invalid username. Use lowercase letters, numbers, underscore, hyphen. Start with letter or underscore.${NC}"
    fi
  done
}

get_password() {
  while true; do
    echo -e "${YELLOW}Enter password for $USERNAME:${NC}"
    read -r -s PASSWORD
    echo ""
    echo -e "${YELLOW}Confirm password:${NC}"
    read -r -s PASSWORD_CONFIRM
    echo ""

    if [ "$PASSWORD" = "$PASSWORD_CONFIRM" ]; then
      if [ ${#PASSWORD} -ge 8 ]; then
        break
      else
        echo -e "${RED}❌ Password must be at least 8 characters long${NC}"
      fi
    else
      echo -e "${RED}❌ Passwords do not match${NC}"
    fi
  done
}

get_timezone() {
  echo -e "${CYAN}🌍 Setting timezone to America/Detroit${NC}"
  TIMEZONE="America/Detroit"

  if ! timedatectl list-timezones | grep -q "^$TIMEZONE$"; then
    echo -e "${RED}❌ Invalid timezone, using UTC${NC}"
    TIMEZONE="UTC"
  fi
}

partition_and_format() {
  echo -e "${MAGENTA}🔄 Partitioning and formatting $TARGET_DISK...${NC}"

  # Create GPT partition table
  run_as_sudo parted -s "$TARGET_DISK" mklabel gpt

  # Create EFI partition (512MB)
  run_as_sudo parted -s "$TARGET_DISK" mkpart ESP fat32 1MiB 513MiB
  run_as_sudo parted -s "$TARGET_DISK" set 1 esp on

  # Create root partition (remaining space)
  run_as_sudo parted -s "$TARGET_DISK" mkpart primary ext4 513MiB 100%

  # Format partitions
  EFI_PART="${TARGET_DISK}1"
  ROOT_PART="${TARGET_DISK}2"

  if [[ "$TARGET_DISK" == *"nvme"* ]]; then
    EFI_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
  fi

  run_as_sudo mkfs.fat -F32 "$EFI_PART"
  run_as_sudo mkfs.ext4 "$ROOT_PART"

  echo -e "${GREEN}✅ Disk partitioning and formatting complete${NC}"
}

mount_filesystems() {
  echo -e "${MAGENTA}🔄 Mounting filesystems...${NC}"

  EFI_PART="${TARGET_DISK}1"
  ROOT_PART="${TARGET_DISK}2"

  if [[ "$TARGET_DISK" == *"nvme"* ]]; then
    EFI_PART="${TARGET_DISK}p1"
    ROOT_PART="${TARGET_DISK}p2"
  fi

  run_as_sudo mount "$ROOT_PART" /mnt
  run_as_sudo mkdir -p /mnt/boot
  run_as_sudo mount "$EFI_PART" /mnt/boot

  echo -e "${GREEN}✅ Filesystems mounted${NC}"
}

install_base_system() {
  echo -e "${MAGENTA}🔄 Installing base Arch Linux system...${NC}"

  # Initialize and populate the keyring
  echo -e "${YELLOW}🔑 Initializing GPG keyring...${NC}"
  run_as_sudo pacman-key --init
  run_as_sudo pacman-key --populate archlinux

  # Install base packages
  run_as_sudo pacstrap /mnt base base-devel linux linux-firmware vim networkmanager openssh sudo

  echo -e "${GREEN}✅ Base system installed${NC}"
}

configure_system() {
  echo -e "${MAGENTA}🔄 Configuring system...${NC}"

  # Generate fstab
  run_as_sudo genfstab -U /mnt >> /mnt/etc/fstab

  # Set timezone
  run_as_sudo arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
  run_as_sudo arch-chroot /mnt hwclock --systohc

  # Set locale
  run_as_sudo arch-chroot /mnt sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
  run_as_sudo arch-chroot /mnt locale-gen
  echo "LANG=$LOCALE" | run_as_sudo tee /mnt/etc/locale.conf

  # Set hostname
  echo "$HOSTNAME" | run_as_sudo tee /mnt/etc/hostname
  echo "127.0.0.1 localhost" | run_as_sudo tee -a /mnt/etc/hosts
  echo "::1 localhost" | run_as_sudo tee -a /mnt/etc/hosts
  echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" | run_as_sudo tee -a /mnt/etc/hosts

  # Set root password
  echo "root:$PASSWORD" | run_as_sudo arch-chroot /mnt chpasswd

  # Create user
  run_as_sudo arch-chroot /mnt useradd -m -G wheel -s /bin/bash "$USERNAME"
  echo "$USERNAME:$PASSWORD" | run_as_sudo arch-chroot /mnt chpasswd

  # Configure sudo
  echo "%wheel ALL=(ALL) ALL" | run_as_sudo tee /mnt/etc/sudoers.d/wheel

  # Install bootloader
  run_as_sudo arch-chroot /mnt pacman -S --noconfirm grub efibootmgr
  run_as_sudo arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  run_as_sudo arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

  echo -e "${GREEN}✅ System configuration complete${NC}"
}

install_server_packages() {
  echo -e "${MAGENTA}🔄 Installing server packages...${NC}"

  # Read packages from the arch server package list
  PACKAGES=$(grep -v '^#' "$DIR/example-packages-arch-server.txt" | grep -v '^$' | tr '\n' ' ')

  # Update package databases and refresh keys inside chroot
  run_as_sudo arch-chroot /mnt pacman-key --refresh-keys
  run_as_sudo arch-chroot /mnt pacman -Sy --noconfirm

  run_as_sudo arch-chroot /mnt pacman -S --noconfirm $PACKAGES

  echo -e "${GREEN}✅ Server packages installed${NC}"
}

enable_services() {
  echo -e "${MAGENTA}🔄 Enabling services...${NC}"

  run_as_sudo arch-chroot /mnt systemctl enable NetworkManager
  run_as_sudo arch-chroot /mnt systemctl enable sshd

  echo -e "${GREEN}✅ Services enabled${NC}"
}

main() {
  # Check if running as root
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ This script must be run as root (sudo)${NC}"
    exit 1
  fi

  show_installer_banner

  if ! confirm "$(echo -e "${YELLOW}Do you want to proceed with Arch Linux installation?${NC}")"; then
    echo -e "${BLUE}Installation cancelled.${NC}"
    exit 0
  fi

  get_disk_info
  select_target_disk
  get_hostname
  get_username
  get_password
  get_timezone

  echo ""
  echo -e "${CYAN}📋 Installation Summary:${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${WHITE}Target Disk: $TARGET_DISK${NC}"
  echo -e "${WHITE}Hostname: $HOSTNAME${NC}"
  echo -e "${WHITE}Username: $USERNAME${NC}"
  echo -e "${WHITE}Timezone: America/Detroit${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if ! confirm "$(echo -e "${RED}Final confirmation: This will WIPE $TARGET_DISK. Continue?${NC}")"; then
    echo -e "${BLUE}Installation cancelled.${NC}"
    exit 0
  fi

  partition_and_format
  mount_filesystems
  install_base_system
  configure_system
  install_server_packages
  enable_services

  echo ""
  echo -e "${GREEN}🎉 Arch Linux installation completed successfully!${NC}"
  echo -e "${WHITE}You can now reboot into your new system.${NC}"
  echo -e "${YELLOW}Don't forget to:${NC}"
  echo -e "${WHITE}  - Remove installation media${NC}"
  echo -e "${WHITE}  - Login with username: $USERNAME${NC}"
  echo -e "${WHITE}  - Configure additional services as needed${NC}"
}

main "$@"
