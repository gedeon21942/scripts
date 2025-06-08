# filepath: /home/nortron/.local/share/scripts/win11.sh
# Read credentials
source /home/nortron/.local/share/scripts/win11_credentials

# Use credentials to connect
sshpass -p "$password" ssh "$username"@192.168.1.25
