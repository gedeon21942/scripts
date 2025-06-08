#!/bin/bash
sudo chown -R $(whoami):$(whoami) ~/.local/share/scripts
chmod -R +x ~/.local/share/scripts
chmod +x ~/.local/share/scripts/*.sh ~/.local/share/scripts/*.py
