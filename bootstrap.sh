#!/bin/bash

echo "█▀▀▀▀▀▄   ▄▀▄   █▀▀▀▀▀▄   ▄▀▄   ▄▀▀▀▀▀▄ ▄▀▀▀▀▀▄ █▄    █
█▄▄▄▄▄▀ ▄▀   ▀▄ █▄▄▄▄▄▀ ▄▀   ▀▄ █       █     █ █ ▀▄  █
█       █▀▀▀▀▀█ █  ▀▄   █▀▀▀▀▀█ █   ▀▀█ █     █ █   ▀▄█
█       █     █ █    ▀▄ █     █ ▀▄▄▄▄▄▀ ▀▄▄▄▄▄▀ █     █"

echo "Installing all packages..."
sudo pacman -S --noconfirm --needed - < packages/pacman.txt

echo "Installing yay..."
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

echo "Installing all yay packages..."
yay -S --noconfirm --needed - < packages/yay.txt

echo "Done!"
