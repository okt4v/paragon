#!/bin/bash
# paragon — Paragon system management CLI

PARAGON_DIR="${PARAGON_DIR:-$HOME/.local/share/paragon}"
TODO_PATH="$HOME/.config/paragon/todos.txt"
CONFIG_DIR="$HOME/.config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "${GREEN}✓${RESET} $1"; }
err()  { echo -e "${RED}✗${RESET} $1" >&2; }
info() { echo -e "${CYAN}→${RESET} $1"; }
warn() { echo -e "${YELLOW}!${RESET} $1"; }

# ── Help ──────────────────────────────────────────────────────────────────────

usage() {
  echo -e "${BOLD}paragon${RESET} — Paragon system management"
  echo ""
  echo -e "${BOLD}USAGE${RESET}"
  echo "  paragon <command> [args]"
  echo ""
  echo -e "${BOLD}COMMANDS${RESET}"
  echo "  update              Pull latest changes and re-apply configs"
  echo "  reload              Reload Hyprland, Waybar, and Mako"
  echo "  dashboard           Refresh the dashboard wallpaper now"
  echo "  edit <config>       Open a config in \$EDITOR"
  echo "  todo [add|done|rm]  Manage dashboard todos"
  echo "  doctor              Check Paragon installation health"
  echo ""
  echo -e "${BOLD}EDIT TARGETS${RESET}"
  echo "  hypr, waybar, mako, ghostty, zsh, nvim, starship, dashboard"
}

# ── update ────────────────────────────────────────────────────────────────────

cmd_update() {
  info "Pulling latest Paragon..."
  if ! git -C "$PARAGON_DIR" pull --ff-only; then
    err "Git pull failed. Resolve conflicts manually in $PARAGON_DIR"
    exit 1
  fi
  ok "Repository updated"

  info "Re-linking configs..."
  bash "$PARAGON_DIR/scripts/symlink.sh"

  info "Reloading desktop..."
  cmd_reload

  info "Refreshing dashboard..."
  cmd_dashboard &

  echo ""
  ok "Paragon is up to date."
}

# ── reload ────────────────────────────────────────────────────────────────────

cmd_reload() {
  # Reload Hyprland config
  if command -v hyprctl &>/dev/null; then
    hyprctl reload &>/dev/null && ok "Hyprland reloaded" || warn "Hyprland reload failed"
  fi

  # Restart Waybar
  if pgrep -x waybar &>/dev/null; then
    pkill -x waybar
    sleep 0.5
    waybar &>/dev/null &
    disown
    ok "Waybar restarted"
  fi

  # Restart Mako
  if pgrep -x mako &>/dev/null; then
    pkill -x mako
    sleep 0.3
    mako &>/dev/null &
    disown
    ok "Mako restarted"
  fi
}

# ── dashboard ─────────────────────────────────────────────────────────────────

cmd_dashboard() {
  if [ ! -f "$PARAGON_DIR/scripts/dashboard.py" ]; then
    err "Dashboard script not found at $PARAGON_DIR/scripts/dashboard.py"
    exit 1
  fi
  info "Generating dashboard wallpaper..."
  python3 "$PARAGON_DIR/scripts/dashboard.py"
}

# ── edit ──────────────────────────────────────────────────────────────────────

cmd_edit() {
  local target="$1"
  local EDITOR="${EDITOR:-nvim}"

  declare -A targets=(
    [hypr]="$CONFIG_DIR/hypr/hyprland.conf"
    [keybinds]="$CONFIG_DIR/hypr/keybinds.conf"
    [appearance]="$CONFIG_DIR/hypr/appearance.conf"
    [autostart]="$CONFIG_DIR/hypr/autostart.conf"
    [waybar]="$CONFIG_DIR/waybar/config.jsonc"
    [waybar-style]="$CONFIG_DIR/waybar/style.css"
    [mako]="$CONFIG_DIR/mako/config"
    [ghostty]="$CONFIG_DIR/ghostty/config"
    [zsh]="$HOME/.zshrc"
    [aliases]="$CONFIG_DIR/zsh/aliases.zsh"
    [nvim]="$CONFIG_DIR/nvim/lua/config/options.lua"
    [starship]="$CONFIG_DIR/starship.toml"
    [dashboard]="$HOME/.config/paragon/dashboard.json"
    [todos]="$TODO_PATH"
  )

  if [ -z "$target" ]; then
    echo -e "${BOLD}Available configs:${RESET}"
    for key in $(echo "${!targets[@]}" | tr ' ' '\n' | sort); do
      printf "  %-16s %s\n" "$key" "${targets[$key]}"
    done
    return
  fi

  local path="${targets[$target]}"
  if [ -z "$path" ]; then
    err "Unknown config: '$target'"
    echo "Run 'paragon edit' with no arguments to see available targets."
    exit 1
  fi

  if [ ! -e "$path" ]; then
    warn "$path does not exist yet — creating it"
    mkdir -p "$(dirname "$path")"
  fi

  $EDITOR "$path"

  # Auto-reload relevant service after editing
  case "$target" in
    hypr|keybinds|appearance|autostart)
      read -rp "Reload Hyprland? [Y/n] " yn </dev/tty
      [[ ! "$yn" =~ ^[Nn]$ ]] && hyprctl reload &>/dev/null && ok "Hyprland reloaded"
      ;;
    waybar|waybar-style)
      read -rp "Restart Waybar? [Y/n] " yn </dev/tty
      if [[ ! "$yn" =~ ^[Nn]$ ]]; then
        pkill -x waybar; sleep 0.5; waybar &>/dev/null & disown
        ok "Waybar restarted"
      fi
      ;;
    mako)
      pkill -x mako; sleep 0.3; mako &>/dev/null & disown
      ok "Mako restarted"
      ;;
    dashboard|todos)
      read -rp "Refresh dashboard wallpaper? [Y/n] " yn </dev/tty
      [[ ! "$yn" =~ ^[Nn]$ ]] && cmd_dashboard
      ;;
  esac
}

# ── todo ──────────────────────────────────────────────────────────────────────

cmd_todo() {
  local subcmd="$1"
  shift || true

  mkdir -p "$(dirname "$TODO_PATH")"
  [ -f "$TODO_PATH" ] || touch "$TODO_PATH"

  case "$subcmd" in
    add|a)
      local text="$*"
      if [ -z "$text" ]; then
        read -rp "Todo: " text </dev/tty
      fi
      echo "[ ] $text" >> "$TODO_PATH"
      ok "Added: $text"
      cmd_dashboard &
      ;;

    done|d)
      local term="$*"
      if [ -z "$term" ]; then
        _todo_pick_and_act done
      else
        sed -i "s/^\[ \] \(.*${term}.*\)$/[x] \1/" "$TODO_PATH"
        ok "Marked done: $term"
        cmd_dashboard &
      fi
      ;;

    rm|remove|r)
      local term="$*"
      if [ -z "$term" ]; then
        _todo_pick_and_act rm
      else
        grep -v "$term" "$TODO_PATH" > /tmp/todos.tmp && mv /tmp/todos.tmp "$TODO_PATH"
        ok "Removed: $term"
        cmd_dashboard &
      fi
      ;;

    clear)
      read -rp "Remove all completed todos? [y/N] " yn </dev/tty
      if [[ "$yn" =~ ^[Yy]$ ]]; then
        grep -v '^\[x\]' "$TODO_PATH" > /tmp/todos.tmp && mv /tmp/todos.tmp "$TODO_PATH"
        ok "Cleared completed todos"
        cmd_dashboard &
      fi
      ;;

    ""|list|ls)
      if [ ! -s "$TODO_PATH" ]; then
        info "No todos. Add one with: paragon todo add <text>"
        return
      fi
      echo ""
      local i=1
      while IFS= read -r line; do
        if [[ "$line" == \[x\]* ]]; then
          echo -e "  ${CYAN}$i${RESET}  ${RESET}$(echo "$line" | sed 's/^\[.\] //')${RESET}"
        else
          echo -e "  ${CYAN}$i${RESET}  ${BOLD}$(echo "$line" | sed 's/^\[.\] //')${RESET}"
        fi
        ((i++))
      done < "$TODO_PATH"
      echo ""
      ;;

    *)
      err "Unknown todo subcommand: $subcmd"
      echo "Usage: paragon todo [list|add|done|rm|clear]"
      exit 1
      ;;
  esac
}

_todo_pick_and_act() {
  local action="$1"
  if ! command -v fzf &>/dev/null; then
    err "fzf not found — pass a search term instead"
    exit 1
  fi
  local selected
  selected=$(cat "$TODO_PATH" | fzf --prompt="Select todo: " < /dev/tty)
  [ -z "$selected" ] && return
  if [ "$action" = "done" ]; then
    escaped=$(printf '%s\n' "$selected" | sed 's/[[\.*^$()+?{|]/\\&/g')
    sed -i "s/^\[ \] \(.*\)$/[x] \1/" "$TODO_PATH"
    ok "Marked done"
  elif [ "$action" = "rm" ]; then
    escaped=$(printf '%s\n' "$selected" | sed 's/[[\.*^$()+?{|]/\\&/g')
    grep -vF "$selected" "$TODO_PATH" > /tmp/todos.tmp && mv /tmp/todos.tmp "$TODO_PATH"
    ok "Removed"
  fi
  cmd_dashboard &
}

# ── doctor ────────────────────────────────────────────────────────────────────

cmd_doctor() {
  echo -e "\n${BOLD}Paragon Doctor${RESET}\n"

  _check() {
    local label="$1"
    local check="$2"
    if eval "$check" &>/dev/null; then
      ok "$label"
    else
      err "$label"
    fi
  }

  _check "Paragon repo present"        "[ -d '$PARAGON_DIR/.git' ]"
  _check "Hyprland installed"          "command -v Hyprland"
  _check "Waybar installed"            "command -v waybar"
  _check "Mako installed"              "command -v mako"
  _check "Ghostty installed"           "command -v ghostty"
  _check "Neovim installed"            "command -v nvim"
  _check "LazyVim present"             "[ -f '$CONFIG_DIR/nvim/.lazyvim' ]"
  _check "zsh installed"               "command -v zsh"
  _check "starship installed"          "command -v starship"
  _check "swww installed"              "command -v swww"
  _check "Claude Code installed"       "command -v claude || [ -x '$HOME/.local/bin/claude' ]"
  _check "Docker running"              "systemctl is-active --quiet docker"
  _check "Mullvad daemon running"      "systemctl is-active --quiet mullvad-daemon"
  _check "Tor running"                 "systemctl is-active --quiet tor"
  _check "Hyprland config linked"      "[ -L '$CONFIG_DIR/hypr' ]"
  _check "Waybar config linked"        "[ -L '$CONFIG_DIR/waybar' ]"
  _check "zshrc present"               "[ -f '$HOME/.zshrc' ]"
  _check "Dashboard config present"    "[ -f '$HOME/.config/paragon/dashboard.json' ]"
  _check "Dashboard timer enabled"     "systemctl --user is-enabled --quiet paragon-dashboard.timer"
  _check "Finance vault present"       "[ -d '$HOME/Finance' ]"

  echo ""
}

# ── Entry point ───────────────────────────────────────────────────────────────

case "$1" in
  update|up)       shift; cmd_update "$@" ;;
  reload|r)        shift; cmd_reload "$@" ;;
  dashboard|dash)  shift; cmd_dashboard "$@" ;;
  edit|e)          shift; cmd_edit "$@" ;;
  todo|t)          shift; cmd_todo "$@" ;;
  doctor|dr)       shift; cmd_doctor "$@" ;;
  help|--help|-h)  usage ;;
  "")              usage ;;
  *)
    err "Unknown command: $1"
    echo ""
    usage
    exit 1
    ;;
esac
