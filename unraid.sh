#!/bin/bash
exec >> /tmp/unraid_sh.log 2>&1
echo "----- $(date) Starting unraid.sh -----"
sudo mount -t cifs //192.168.1.12/downloads /mnt/share/unraid/downloads -o credentials=/etc/samba/credentials_unraid,vers=3.0
sudo mount -t cifs //192.168.1.12/appdata /mnt/share/unraid/appdata -o credentials=/etc/samba/credentials_unraid,vers=3.0
sudo mount -t cifs //192.168.1.12/domains /mnt/share/unraid/domain -o credentials=/etc/samba/credentials_unraid,vers=3.0
sudo mount -t cifs //192.168.1.12/Data /mnt/share/unraid/Data -o credentials=/etc/samba/credentials_unraid,vers=3.0
sudo mount -t cifs //192.168.1.12/Backups /mnt/share/unraid/Backup -o credentials=/etc/samba/credentials_unraid,vers=3.0
sudo mount -t cifs //192.168.1.12/isos /mnt/share/unraid/isos -o credentials=/etc/samba/credentials_unraid,vers=3.0
