#!/bin/bash

# Send Wake-on-LAN packet
wol_mac="7c:10:c9:22:27:4F"
wakeonlan $wol_mac

# Check if the machine is already online
if ping -c 1 -W 1 192.168.1.80 >/dev/null 2>&1; then
    echo "Machine is already online, skipping sleep."
else
    echo "Waiting for the machine to wake up..."
    sleep 25
fi

# Launch Remmina to RDP into the machine
remmina -c ~/.local/share/remmina/group_rdp_desktop_192-168-1-80.remmina