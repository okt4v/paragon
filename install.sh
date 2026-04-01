#!/bin/bash
set -e

REPO_URL="https://github.com/okt4v/paragon.git"
INSTALL_DIR="$HOME/.local/share/paragon"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "█▀▀▀▀▀▄   ▄▀▄   █▀▀▀▀▀▄   ▄▀▄   ▄▀▀▀▀▀▄ ▄▀▀▀▀▀▄ █▄    █"
echo "█▄▄▄▄▄▀ ▄▀   ▀▄ █▄▄▄▄▄▀ ▄▀   ▀▄ █       █     █ █ ▀▄  █"
echo "█       █▀▀▀▀▀█ █  ▀▄   █▀▀▀▀▀█ █   ▀▀█ █     █ █   ▀▄█"
echo "█       █     █ █    ▀▄ █     █ ▀▄▄▄▄▄▀ ▀▄▄▄▄▄▀ █     █"
echo -e "${RESET}"
echo -e "${BOLD}The perfect system configuration${RESET}"
echo ""

# Ensure git and curl are available
if ! command -v git &>/dev/null; then
  echo -e "${CYAN}Installing git...${RESET}"
  sudo pacman -S --noconfirm --needed git
fi

if ! command -v curl &>/dev/null; then
  echo -e "${CYAN}Installing curl...${RESET}"
  sudo pacman -S --noconfirm --needed curl
fi

# Clone or update the repo
if [ -d "$INSTALL_DIR/.git" ]; then
  echo -e "${CYAN}Updating existing Paragon installation...${RESET}"
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo -e "${CYAN}Cloning Paragon to $INSTALL_DIR...${RESET}"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

echo ""
echo -e "${GREEN}Running bootstrap...${RESET}"
echo ""

cd "$INSTALL_DIR"
bash bootstrap.sh
