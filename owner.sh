#!/bin/bash
sudo chown -R $(whoami):$(whoami) ~/.local/share/scripts

# Make all .sh and .py files executable, but skip Keybinds.conf
find ~/.local/share/scripts -type f \( -name "*.sh" -o -name "*.py" \) ! -name "Keybinds.conf" -exec chmod +x {} \;
