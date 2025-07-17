#!/bin/bash

# Configuration
USERNAME="root" # Unraid's SSH user is typically 'root'
HOSTNAME="192.168.1.12"
VM_NAME="archy" # Replace with the exact name of your VM

# --- Check VM status ---
VM_STATUS=$(ssh "$USERNAME@$HOSTNAME" "virsh list --all | grep -i \"$VM_NAME\" | awk '{print \$3}'")

if [[ "$VM_STATUS" == "running" ]]; then
    echo "VM $VM_NAME is already running. Skipping start and sleep."
else
    # --- Start the VM ---
    echo "Attempting to start VM: $VM_NAME on Unraid server: $HOSTNAME"
    ssh "$USERNAME@$HOSTNAME" "virsh start \"$VM_NAME\""

    # --- Optional: Check VM status afterwards ---
    echo -e "\nChecking VM status..."
    ssh "$USERNAME@$HOSTNAME" "virsh list --all | grep -i \"$VM_NAME\""

    echo -e "\nVM started. Waiting for 15 seconds..."
    sleep 15
fi

# --- Connect to the VM in a new terminal ---
echo "Connecting to the VM in a new terminal on workspace 4..."
kitty --title "Archy VM" ssh nortron@192.168.1.36

# Move the terminal to workspace 4 (Hyprland-specific command)
hyprctl dispatch workspace 4



