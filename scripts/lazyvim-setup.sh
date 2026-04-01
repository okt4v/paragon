#!/bin/bash
# lazyvim-setup.sh — install LazyVim into ~/.config/nvim

set -e

NVIM_CONFIG="$HOME/.config/nvim"
LAZYVIM_STARTER="https://github.com/LazyVim/starter"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}Setting up LazyVim...${RESET}"

# Back up existing nvim config
if [ -d "$NVIM_CONFIG" ] && [ ! -f "$NVIM_CONFIG/.lazyvim" ]; then
  BACKUP="$NVIM_CONFIG.bak.$(date +%s)"
  echo -e "${YELLOW}Backing up existing nvim config to $BACKUP${RESET}"
  mv "$NVIM_CONFIG" "$BACKUP"
fi

if [ -f "$NVIM_CONFIG/.lazyvim" ]; then
  echo -e "${GREEN}LazyVim already installed — skipping clone${RESET}"
else
  # Clone LazyVim starter
  git clone "$LAZYVIM_STARTER" "$NVIM_CONFIG"

  # Remove starter's git history so user owns the config
  rm -rf "$NVIM_CONFIG/.git"

  # Mark as lazyvim-managed
  touch "$NVIM_CONFIG/.lazyvim"
fi

# Apply Paragon custom extras (if any exist)
PARAGON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM_EXTRAS="$PARAGON_DIR/configs/nvim"

if [ -d "$NVIM_EXTRAS" ]; then
  echo -e "${CYAN}Applying Paragon nvim extras...${RESET}"
  cp -r "$NVIM_EXTRAS/." "$NVIM_CONFIG/"
fi

echo -e "${GREEN}✓ LazyVim ready at $NVIM_CONFIG${RESET}"
echo -e "  Open nvim and LazyVim will finish installing plugins on first launch."
