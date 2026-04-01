# ── Paragon .zshrc ────────────────────────────────────────────────────────────

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# Options
setopt AUTO_CD
setopt CORRECT
setopt NO_BEEP

# ── Plugins ───────────────────────────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── fzf ───────────────────────────────────────────────────────────────────────
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border rounded \
  --color=bg+:#1e293b,bg:#0f172a,spinner:#5eead4,hl:#38bdf8 \
  --color=fg:#cbd5e1,header:#64748b,info:#5eead4,pointer:#5eead4 \
  --color=marker:#5eead4,fg+:#e2e8f0,prompt:#5eead4,hl+:#38bdf8"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# ── zoxide (smart cd) ─────────────────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── Starship prompt ───────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── Path ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/share/npm/bin:$PATH"

# ── Aliases ───────────────────────────────────────────────────────────────────
source ~/.config/zsh/aliases.zsh

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR=nvim
export VISUAL=nvim

# ── Wayland ───────────────────────────────────────────────────────────────────
export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-0}
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland

# ── Autosuggestion style ──────────────────────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#475569'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ── Completion ────────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
