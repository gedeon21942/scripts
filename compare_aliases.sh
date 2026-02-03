#!/bin/zsh

LOCAL_FILE="$HOME/.aliases.zsh"
SERVER_FILE="/mnt/share/unraid/Backup/Arch/server/.aliases.zsh"

# Ensure Unraid shares are mounted
if [ ! -d "/mnt/share/unraid/Backup" ]; then
    echo "Mounting Unraid shares..."
    bash "$HOME/.local/share/scripts/unraid.sh"
fi

if [ ! -f "$SERVER_FILE" ]; then
    echo "Error: Server file not found at $SERVER_FILE"
    echo "Make sure Unraid is mounted and the path is correct."
    read "?Press Enter to exit..."
    exit 1
fi

echo "Comparing local file ($LOCAL_FILE) with server file ($SERVER_FILE)..."
echo ""

# Check for differences
if diff -u --color=always "$LOCAL_FILE" "$SERVER_FILE"; then
    echo ""
    echo "Files are identical."
else
    echo ""
    echo "--------------------------------------------------"
    echo "Files differ. Choose an action:"
    echo "1) Replace LOCAL file with SERVER version (Pull)"
    echo "2) Replace SERVER file with LOCAL version (Push)"
    echo "3) Do nothing"
    echo ""
    read "choice?Enter choice (1/2/3): "

    case "$choice" in
        1)
            sudo cp "$SERVER_FILE" "$LOCAL_FILE"
            sudo chown "$USER":"$USER" "$LOCAL_FILE"
            echo "Local .aliases.zsh updated from server."
            source "$HOME/.zshrc"
            ;;
        2)
            sudo cp "$LOCAL_FILE" "$SERVER_FILE"
            echo "Server .aliases.zsh updated from local."
            ;;
        *)
            echo "No changes made."
            ;;
    esac
fi

echo ""
read "?Press Enter to close..."