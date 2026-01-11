#!/bin/bash

# Configuration
USERNAME="root" # Unraid's SSH user is typically 'root'
HOSTNAME="192.168.1.121"
VM_NAME="work11" # Replace with the exact name of your VM

# --- Option 1: Start a VM ---
echo "Attempting to start VM: $VM_NAME on Unraid server: $HOSTNAME"
ssh "$USERNAME@$HOSTNAME" "virsh start \"$VM_NAME\""

# Explanation of the command:
# ssh "$USERNAME@$HOSTNAME"  : Connects to your Unraid server via SSH.
# "virsh start \"$VM_NAME\"" : This is the command executed on the remote Unraid server.
#                              - virsh: The command-line tool for libvirt.
#                              - start: The virsh subcommand to start a VM.
#                              - \"$VM_NAME\": The VM name. Crucially, if your VM name has spaces,
#                                             you MUST enclose it in double quotes, and those
#                                             quotes need to be escaped for the local shell
#                                             so they are passed to the remote shell.

# --- Optional: Check VM status afterwards ---
echo -e "\nChecking VM status..."
ssh "$USERNAME@$HOSTNAME" "virsh list --all | grep -i \"$VM_NAME\""

# Check if the machine is already online
if ping -c 1 -W 1 192.168.1.60 >/dev/null 2>&1; then
    echo "Machine is already online, skipping sleep."
else
    echo "Waiting for the machine to wake up..."
    sleep 15
fi

echo -e "\nScript execution complete."
remmina -c ~/.local/share/remmina/group_rdp_work_192-168-1-60.remmina





