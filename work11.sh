#!/bin/bash

# Configuration
USERNAME="nortron" # Unraid's SSH user is typically 'root'
HOSTNAME="192.168.1.140"
VM_NAME="work" # Replace with the exact name of your VM
# --- Check VM status ---
VM_STATUS=$(ssh "$USERNAME@$HOSTNAME" "virsh list --all | grep -i \"$VM_NAME\" | awk '{print \$3}'")

if [[ "$VM_STATUS" == "running" ]]; then
    echo "VM $VM_NAME is already running."
else
    # --- Start the VM ---
    echo "Attempting to start VM: $VM_NAME on Unraid server: $HOSTNAME"
    ssh "$USERNAME@$HOSTNAME" "virsh start \"$VM_NAME\""

    # --- Optional: Check VM status afterwards ---
    echo -e "\nChecking VM status..."
    ssh "$USERNAME@$HOSTNAME" "virsh list --all | grep -i \"$VM_NAME\""
fi

# Check if the machine is already online
if ping -c 1 -W 1 192.168.1.159 >/dev/null 2>&1; then
    echo "Machine is already online, skipping sleep."
else
    echo "Waiting for the machine to wake up..."
    sleep 15
fi

echo -e "\nScript execution complete."
remmina -c ~/.local/share/remmina/group_rdp_work_192-168-1-159.remmina
