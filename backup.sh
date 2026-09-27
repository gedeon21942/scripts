#!/bin/bash
set -Eeuo pipefail

TIMESHIFT_MOUNT=/mnt/share/timeshift
BACKUP_MOUNT=/mnt/share/unraid/Backup
BACKUP_DEST="$BACKUP_MOUNT/Arch/laptop"
TIMESHIFT_DEVICE_UUID=$(sudo awk -F'"' '/backup_device_uuid/ {print $4; exit}' /etc/timeshift/timeshift.json)
TIMESHIFT_DEVICE="/dev/disk/by-uuid/$TIMESHIFT_DEVICE_UUID"
TIMESHIFT_MOUNTED=false
UNRAID_MOUNTED=false

cleanup() {
    if [[ "$TIMESHIFT_MOUNTED" == true ]]; then
        sudo umount "$TIMESHIFT_MOUNT"
    fi
    if [[ "$UNRAID_MOUNTED" == true ]]; then
        bash ~/.local/share/scripts/uunraid.sh || true
    fi
}
trap cleanup EXIT

sudo timeshift --create

# Run the Unraid script and verify that the destination share is mounted.
UNRAID_MOUNTED=true
bash ~/.local/share/scripts/unraid.sh
if ! mountpoint -q "$BACKUP_MOUNT"; then
    echo "Unraid backup share is not mounted: $BACKUP_MOUNT" >&2
    exit 1
fi

# Mount the configured Timeshift partition.
sudo mount "$TIMESHIFT_DEVICE" "$TIMESHIFT_MOUNT"
TIMESHIFT_MOUNTED=true

# Find the latest snapshot.
LATEST_SNAPSHOT=$(find "$TIMESHIFT_MOUNT/timeshift/snapshots" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -nr | sed 's/^[^ ]* //; 1q')
if [[ -z "$LATEST_SNAPSHOT" ]]; then
    echo "No snapshots found. Exiting." >&2
    exit 1
fi

echo "Latest snapshot found: $LATEST_SNAPSHOT"
sudo rsync -avh --delete "$LATEST_SNAPSHOT/" "$BACKUP_DEST/"
echo "Backup of the latest snapshot completed successfully."
