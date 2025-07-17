#!/bin/bash

# Configuration
USERNAME="root" # Unraid's SSH user is typically 'root'
HOSTNAME="192.168.1.12"
VM_NAMES=("w11" "archy") # List of VMs to shut down

# --- Stop VMs ---
for VM_NAME in "${VM_NAMES[@]}"; do
    echo "Attempting to stop VM: $VM_NAME on Unraid server: $HOSTNAME"
    ssh "$USERNAME@$HOSTNAME" "virsh shutdown \"$VM_NAME\""
done

# --- Optional: Check VM statuses afterwards ---
echo -e "\nChecking VM statuses..."
for VM_NAME in "${VM_NAMES[@]}"; do
    ssh "$USERNAME@$HOSTNAME" "virsh list --all | grep -i \"$VM_NAME\""
done
# --- Open URL ---
#echo -e "\nOpening URL: http://192.168.1.80:5001"
#xdg-open "http://192.168.1.80:5001"
curl http://192.168.1.80:5001

# Run uunraid.sh at the end
bash /home/nortron/.local/share/scripts/uunraid.sh

echo -e "\nScript execution complete."
