#!/bin/bash

# Configuration
USERNAME="nortron" # Unraid's SSH user is typically 'root'
HOSTNAME="192.168.1.55"
VM_NAME="tarch" # Replace with the exact name of your VM

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





remmina -c ~/.local/share/remmina/group_vnc_tarch_192-168-1-63.remmina