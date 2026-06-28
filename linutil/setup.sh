
#!/usr/bin/env bash
set -euo pipefail

# Minimal idempotent setup script to install neovim, openssh-server and samba,
# enable/start services, and configure a simple writable guest Samba share.

SHARE_DIR=/srv/samba/share
SMB_CONF=/etc/samba/smb.conf

command_exists() { command -v "$1" >/dev/null 2>&1; }

install_packages() {
	if command_exists apt-get; then
		export DEBIAN_FRONTEND=noninteractive
		apt-get update
		apt-get install -y neovim zsh openssh-server samba
	elif command_exists dnf; then
		dnf install -y neovim zsh openssh-server samba
	elif command_exists yum; then
		yum install -y epel-release || true
		yum install -y neovim zsh openssh-server samba
	elif command_exists pacman; then
		pacman -Sy --noconfirm neovim zsh openssh samba
	else
		echo "No supported package manager found (apt/dnf/yum/pacman)." >&2
		exit 1
	fi
}

enable_and_start_ssh() {
	# Try common service names
	if systemctl list-unit-files | grep -q '^ssh.service'; then
		systemctl enable --now ssh.service
	elif systemctl list-unit-files | grep -q '^sshd.service'; then
		systemctl enable --now sshd.service
	else
		# fallback: try both
		systemctl enable --now ssh || true
		systemctl enable --now sshd || true
	fi
}

configure_samba_share() {
	mkdir -p "$SHARE_DIR"
	# Set permissive permissions so it's easy to connect from other machines
	chmod 0777 "$SHARE_DIR"

	# Choose sensible owner if group exists
	if getent group nogroup >/dev/null 2>&1; then
		chown nobody:nogroup "$SHARE_DIR" || true
	elif getent group nobody >/dev/null 2>&1; then
		chown nobody:nobody "$SHARE_DIR" || true
	fi

	# Backup smb.conf if not already backed up
	if [ -f "$SMB_CONF" ] && [ ! -f "${SMB_CONF}.copilot.bak" ]; then
		cp "$SMB_CONF" "${SMB_CONF}.copilot.bak"
	fi

	# Add share block if not already present (marker-based)
	if ! grep -q '# BEGIN COPILOT SAMBA SHARE' "$SMB_CONF" 2>/dev/null; then
		cat >> "$SMB_CONF" <<'EOF'

# BEGIN COPILOT SAMBA SHARE
[sambashare]
	 path = /srv/samba/share
	 browsable = yes
	 read only = no
	 guest ok = yes
	 force user = nobody
	 create mask = 0777
	 directory mask = 0777
# END COPILOT SAMBA SHARE

EOF
	fi

	# Start/enable Samba services
	if systemctl list-unit-files | grep -q '^smbd.service'; then
		systemctl enable --now smbd.service nmbd.service || true
	elif systemctl list-unit-files | grep -q '^samba.service'; then
		systemctl enable --now samba.service || true
	else
		systemctl enable --now smbd nmbd || true
	fi
}

configure_zsh() {
	# Set zsh as default shell for the invoking user (SUDO_USER) or current user
	local target_user
	target_user="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER") }"

	if [ -z "$target_user" ] || [ "$target_user" = "root" ]; then
		echo "No non-root user detected to change shell for; skipping chsh." 
		return 0
	fi

	if ! command_exists zsh; then
		echo "zsh not found; skipping shell change." >&2
		return 1
	fi

	local zsh_path
	zsh_path=$(command -v zsh || true)
	if [ -z "$zsh_path" ]; then
		echo "Could not locate zsh binary." >&2
		return 1
	fi

	if command_exists chsh; then
		echo "Changing default shell for $target_user to $zsh_path"
		chsh -s "$zsh_path" "$target_user" || true
	else
		echo "chsh not available; please change the shell for $target_user manually: sudo chsh -s $zsh_path $target_user"
	fi
}

main() {
	echo "Installing packages..."
	install_packages

	echo "Enabling and starting SSH service..."
	enable_and_start_ssh

	echo "Configuring zsh for user..."
	configure_zsh || true

	echo "Configuring Samba and share directory at $SHARE_DIR..."
	configure_samba_share

	echo "Setup complete. Samba share is available at //$(hostname -I | awk '{print $1}')/sambashare (guest access)."
	echo "If you prefer authenticated access, create a samba user with: smbpasswd -a <username>"
}

main "$@"

