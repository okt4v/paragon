#!/bin/bash

echo "█▀▀▀▀▀▄   ▄▀▄   █▀▀▀▀▀▄   ▄▀▄   ▄▀▀▀▀▀▄ ▄▀▀▀▀▀▄ █▄    █
█▄▄▄▄▄▀ ▄▀   ▀▄ █▄▄▄▄▄▀ ▄▀   ▀▄ █       █     █ █ ▀▄  █
█       █▀▀▀▀▀█ █  ▀▄   █▀▀▀▀▀█ █   ▀▀█ █     █ █   ▀▄█
█       █     █ █    ▀▄ █     █ ▀▄▄▄▄▄▀ ▀▄▄▄▄▄▀ █     █"

echo "Installing all packages..."
sudo pacman -S --noconfirm --needed - < packages/pacman.txt

echo "Installing yay..."
if command -v yay >/dev/null 2>&1; then
  echo "yay already installed: $(command -v yay)"
else
  cd /tmp || exit 1
  if [ -d yay ]; then rm -rf yay; fi
  git clone https://aur.archlinux.org/yay.git
  cd yay || exit 1
  makepkg -si --noconfirm
fi

echo "Installing all yay packages..."
yay -S --noconfirm --needed - < packages/yay.txt

echo "Done!"
