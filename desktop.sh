#!/bin/bash

# Check if the machine is already online (checking RDP port 3389)
if timeout 1 bash -c 'echo > /dev/tcp/192.168.1.80/3389' >/dev/null 2>&1; then
    echo "Machine is already online, skipping sleep."
else
    # Send Wake-on-LAN packet
    wol_mac="7c:10:c9:22:27:4F"
    wakeonlan $wol_mac
    echo "Waiting for the machine to wake up..."
    sleep 25
fi

# Launch Remmina to RDP into the machine
remmina -c ~/.local/share/remmina/group_rdp_desktop_192-168-1-80.remmina