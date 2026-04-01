# ── Navigation ────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias proj='cd ~/Projects'
alias fin='cd ~/Finance'
alias dl='cd ~/Downloads'

# ── Modern replacements ───────────────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=plain'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias vim='nvim'
alias vi='nvim'
alias zj='zellij'

# ── Git ───────────────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gst='git stash'
alias gstp='git stash pop'
alias lg='lazygit'

# ── Docker ────────────────────────────────────────────────────────────────────
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias dstop='docker stop $(docker ps -q)'
alias dprune='docker system prune -af'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias ld='lazydocker'

# ── Python ────────────────────────────────────────────────────────────────────
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv .venv && source .venv/bin/activate'
alias activate='source .venv/bin/activate'

# ── System ────────────────────────────────────────────────────────────────────
alias update='sudo pacman -Syu && yay -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; yay -Sc'
alias ports='ss -tulnp'
alias myip='curl -s ifconfig.me'
alias paths='echo $PATH | tr : "\n"'
alias reload='source ~/.zshrc'
alias top='btop'

# ── Finance / Investing ───────────────────────────────────────────────────────
alias ticker='tickrs'
alias prices='tickrs -s BTC-USD,ETH-USD,SPY,QQQ'
alias fin-scripts='cd ~/Projects/finance-scripts 2>/dev/null || cd ~/Finance'

# ── Clipboard (Wayland) ───────────────────────────────────────────────────────
alias copy='wl-copy'
alias paste='wl-paste'

# ── Misc ──────────────────────────────────────────────────────────────────────
alias q='exit'
alias c='clear'
alias h='history | fzf'
alias mk='mkdir -p'
