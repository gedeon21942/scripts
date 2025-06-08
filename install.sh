#!/bin/bash

# Add nortron to sudoers with NOPASSWD for all commands
echo "nortron ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/nortron-nopasswd

# Set correct permissions
sudo chmod 0440 /etc/sudoers.d/nortron-nopasswd

echo "nortron can now use sudo without a password."

# Update system (Arch Linux)
sudo pacman -Syu --noconfirm

# Install neovim, remmina (with RDP plugin), and brave
sudo pacman -S --noconfirm neovim remmina remmina-plugin-rdp cifs-utils timeshift samba tk
# Install timeshift for system snapshots
# Install cifs-utils for mounting CIFS shares

# Install openssh
sudo pacman -S --noconfirm openssh

# Enable and start the SSH server
sudo systemctl enable sshd
sudo systemctl start sshd

echo "OpenSSH server installed, enabled, and started."

# Install Brave browser (from AUR, needs yay or paru)
if command -v yay &>/dev/null; then
    yay -S --noconfirm brave-bin
elif command -v paru &>/dev/null; then
    paru -S --noconfirm brave-bin
else
    echo "Please install yay or paru to install Brave browser from AUR."
fi


# Create folder structure for unraid shares

sudo mkdir -p /mnt/share/unraid/isos
sudo mkdir -p /mnt/share/unraid/downloads
sudo mkdir -p /mnt/share/unraid/domain
sudo mkdir -p /mnt/share/unraid/appdata
sudo mkdir -p /mnt/share/unraid/Data
sudo mkdir -p /mnt/share/unraid/Backup
sudo mkdir -p /mnt/share/timeshift
echo "Created /mnt/share/unraid/Backups, /mnt/share/unraid/isos, and /mnt/share/unraid/downloads"
sudo mv ~/.local/share/scripts/credentials_unraid  /etc/samba/credentials_unraid
echo "Moved credentials_unraid to /etc/samba/credentials_unraid"
bash ~/.local/share/scripts/unraid.sh
# Copy .zshrc to home directory and source it
sudo mv ~/.local/share/scripts/.zshrc ~/
echo "Moved .zshrc to home directory."

echo "Sourced .zshrc"
sudo cp -r /mnt/share/unraid/Backup/Arch/.remmina ~/.config/remmina 
sudo cp -r /mnt/share/unraid/Backup/Arch/remmina ~/.local/share/remmina 
echo "Copied Remmina configuration to /remmina"
sudo mv ~/.local/share/scripts/Keybinds.conf ~/.conf/hypr/configs/Keybinds.conf
# Install Visual Studio Code (from AUR, needs yay or paru)
if command -v yay &>/dev/null; then
    yay -S --noconfirm visual-studio-code-bin
elif command -v paru &>/dev/null; then
    paru -S --noconfirm visual-studio-code-bin
else
    echo "Please install yay or paru to install Visual Studio Code from AUR."
fi
