# ~/.bash_aliases
# This file is sourced by .bashrc

# ============================================================================
# ENHANCED LS ALIASES
# ============================================================================
alias ll='ls -alF'          # long format with file type indicators
alias la='ls -A'            # all files except . and ..
alias lt='ls -ltr'          # sort by modification time, newest last
alias lh='ls -lah'          # human readable sizes
alias lsd='ls -la | grep "^d"'  # list only directories

# ============================================================================
# NAVIGATION ALIASES
# ============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'           # go back to previous directory

# ============================================================================
# SAFETY ALIASES
# ============================================================================
alias rm='rm -i'            # prompt before removal
alias cp='cp -i'            # prompt before overwrite
alias mv='mv -i'            # prompt before overwrite
alias mkdir='mkdir -pv'     # create parent directories and be verbose

# ============================================================================
# COLORED GREP
# ============================================================================
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ============================================================================
# SYSTEM MONITORING
# ============================================================================
alias df='df -h'            # human readable disk usage
alias du='du -h'            # human readable directory usage
alias free='free -h'        # human readable memory usage
alias ps='ps auxf'          # detailed process list
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e' # search processes

# ============================================================================
# APT ALIASES
# ============================================================================
alias aptup='sudo apt update && sudo apt upgrade'
alias aptin='sudo apt install'
alias aptse='apt search'
alias aptsh='apt show'
alias aptli='apt list --installed'
alias aptug='apt list --upgradable'

# ============================================================================
# MODERN TOOL ALIASES (if installed)
# ============================================================================

# Better cat with syntax highlighting
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias ccat='/bin/cat'   # fallback to original cat
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --paging=never'
    alias ccat='/bin/cat'
fi

# Better find
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
    alias oldfind='/usr/bin/find'
elif command -v fdfind >/dev/null 2>&1; then
    alias find='fdfind'
    alias oldfind='/usr/bin/find'
fi

# Better grep
if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
    alias oldgrep='/bin/grep'
fi

# ============================================================================
# GIT ALIASES
# ============================================================================
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Create directory and enter it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ] ; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *.xz)        unxz "$1"        ;;
            *.lzma)      unlzma "$1"      ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Show disk usage of directories in current path, sorted
dud() {
    du -h --max-depth=1 "$@" | sort -hr
}

# Quick weather check (requires curl)
weather() {
    local city="${1:-Liverpool}"
    curl -s "wttr.in/$city?format=3"
}

# Quick IP check
myip() {
    curl -s ifconfig.me
    echo
}

# Search command history
h() {
    if [ $# -eq 0 ]; then
        history
    else
        history | grep -i "$1"
    fi
}

# ls options doesn't allow for the sorting I want, so using AWK here.
# Inspired by https://github.com/RichardBronosky/dotfiles
# and https://stackoverflow.com/a/51141872/2271042
l() {
    ls -Ahl --color=always $* | awk -f ~/.ls.awk; 
}

# Kubernetes shortcuts
if command -v kubectl >/dev/null 2>&1; then
    alias k='kubectl'
    complete -F __start_kubectl k
    
  # set the copied k3s config as KUBECONFIG, so that sudo is not necessary to run kubectl
  # see https://github.com/k3s-io/k3s/issues/389#issuecomment-745808339
    export KUBECONFIG=~/.kube/k3s-config
fi

# Package upgrade information function
apt-upgrade-info() {
    local output=""
    local count=0
    
    # Check if there are any upgradable packages first
    if ! apt list --upgradable 2>/dev/null | grep -q '^[^W]'; then
        echo "No packages available for upgrade."
        return 0
    fi
    
    for pkg in $(apt list --upgradable 2>/dev/null | tail -n +2 | cut -d'/' -f1); do
        # Color codes (using local to avoid polluting environment)
        local BRIGHT_BLUE='\033[1;94m'
        local GREEN='\033[1;32m'
        local YELLOW='\033[1;33m'
        local CYAN='\033[1;36m'
        local RED='\033[1;31m'
        local MAGENTA='\033[1;35m'
        local NC='\033[0m' # No Color
        
        output+="\n${BRIGHT_BLUE}=== $pkg ===${NC}\n"
        
        # Get current and new versions
        local current_version=$(dpkg -l 2>/dev/null | grep "^ii  $pkg " | awk '{print $3}')
        local new_version=$(apt list --upgradable 2>/dev/null | grep "^$pkg/" | cut -d' ' -f2)
        
        if [ -z "$current_version" ]; then
            output+="${MAGENTA}Installing:${NC} ${GREEN}$new_version${NC}\n\n"
        else
            output+="${YELLOW}Upgrading:${NC} ${RED}$current_version${NC} ${CYAN}→${NC} ${GREEN}$new_version${NC}\n\n"
        fi
        
        # Get full description with colored first line
        local description=$(apt-cache show $pkg 2>/dev/null | sed -n '/^Description-en:/,/^[^ ]/p' | sed '$d' | sed 's/^Description-en: //' | sed 's/^ //')
        local first_line=$(echo "$description" | head -n1)
        local rest_lines=$(echo "$description" | tail -n +2)
        
        output+="${CYAN}$first_line${NC}\n"
        output+="$rest_lines\n\n"
        
        ((count++))
    done
    
    # Use less if more than 5 packages, otherwise print directly
    if [ $count -gt 5 ]; then
        echo -e "$output" | less -R
    else
        echo -e "$output"
    fi
}