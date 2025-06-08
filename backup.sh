

#!/bin/bash
sudo timeshift --create
# Run the Unraid script
bash ~/.local/share/scripts/unraid.sh

# Mount the timeshift partition
sudo mount /dev/sda3 /mnt/share/timeshift

# Find the latest snapshot
LATEST_SNAPSHOT=$(ls -td /mnt/share/timeshift/timeshift/snapshots/* | head -1)

# Check if a snapshot exists
if [[ -z "$LATEST_SNAPSHOT" ]]; then
    echo "No snapshots found. Exiting."
    sudo umount /mnt/share/timeshift
    exit 1
fi

echo "Latest snapshot found: $LATEST_SNAPSHOT"

# Use rsync to copy the latest snapshot to the backup folder
sudo rsync -avh --delete "$LATEST_SNAPSHOT/" /mnt/share/unraid/Backup/Arch/laptop/

# Unmount the timeshift partition
sudo umount /mnt/share/timeshift
bash ~/.local/share/scripts/uunraid.sh
echo "Backup of the latest snapshot completed successfully."
