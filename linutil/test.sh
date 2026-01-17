#!/bin/bash

# Install Arch server packages like Chris Titus' linutil
sudo pacman -S --noconfirm $(grep -v '^#' example-packages-arch-server.txt | tr '\n' ' ')

# Enable server services
sudo systemctl enable --now sshd
sudo systemctl enable --now nginx
sudo systemctl enable --now postgresql
sudo systemctl enable --now docker
sudo systemctl enable --now valkey  # redis alternative
sudo systemctl enable --now NetworkManager