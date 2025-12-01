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
alias psg='ps aux | grep -v grep | grep -i' # search processes

# ============================================================================
# APT ALIASES
# ============================================================================
# Note: aptup is now a function (see UTILITY FUNCTIONS section)
alias aptin='sudo apt install'
alias aptse='apt search'
alias aptsh='apt show'
alias aptli='apt list --installed'
alias aptug='apt list --upgradable'

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
# OTHER ALIASES
# ============================================================================
# Network
alias ports='ss -tulanp' 

# System info
alias sysinfo='inxi -Fxz'

# Docker (if used)
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

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
            *.tar.xz)    tar xf "$1"      ;;
            *.tar.zst)   tar xf "$1"      ;;
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

weather() {
    local city="${1:-Glasgow}"  # Just use Glasgow directly
    curl -s "wttr.in/$city?format=3"
}

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

# Smart apt upgrade with Btrfs snapshot
# Replaces the simple 'aptup' alias with snapshot protection
aptup() {
    echo "Checking for updates..."
    sudo apt update

    # Check if any upgrades are available
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
    
    if [ "$UPGRADABLE" -eq 0 ]; then
        return 0
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "$UPGRADABLE package(s) available for upgrade:"
    echo "═══════════════════════════════════════════════════════════"
    apt list --upgradable 2>/dev/null | grep -v "Listing"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    
    # Ask for confirmation (as regular user, no sudo)
    read -p "Proceed with upgrade? [y/N] " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Upgrade cancelled."
        return 0
    fi

    # Track if snapshot was created
    SNAPSHOT_CREATED=false

    # Create snapshot if snapper is available
    if command -v snapper &> /dev/null; then
        echo ""
        echo "Creating pre-upgrade snapshot..."
        SNAPSHOT_DESC="Before upgrade: $UPGRADABLE packages"
        sudo snapper -c root create --description "$SNAPSHOT_DESC" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✓ Snapshot created: $SNAPSHOT_DESC"
            SNAPSHOT_CREATED=true
        else
            echo "✗ Snapshot creation failed!"
            echo ""
            read -p "Continue with upgrade anyway (NOT RECOMMENDED)? [y/N] " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Upgrade cancelled for safety."
                return 0
            fi
            echo "⚠ Proceeding without snapshot..."
        fi
    fi

    echo ""
    echo "Running upgrade..."
    echo "═══════════════════════════════════════════════════════════"
    sudo apt full-upgrade -y

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Upgrade completed successfully"
        
        # Only show rollback instructions if snapshot was actually created
        if [ "$SNAPSHOT_CREATED" = true ]; then
            echo ""
            echo "If something breaks, rollback with:"
            echo "  sudo snapper -c root list"
            echo "  sudo snapper -c root rollback"
            echo "  reboot"
        fi
    else
        echo ""
        echo "✗ Upgrade failed - check errors above"
        return 1
    fi
}

# Kubernetes shortcuts
if command -v kubectl >/dev/null 2>&1; then
    # set the copied k3s config as KUBECONFIG, so that sudo is not necessary to run kubectl
    # see https://github.com/k3s-io/k3s/issues/389#issuecomment-745808339
    export KUBECONFIG=~/.kube/k3s-config

    # Set alias for kubectl
    alias k='kubectl'

    # Enable kubectl bash completion
    source <(kubectl completion bash)

    # Associate the completion logic with the 'k' alias
    complete -o default -F __start_kubectl k
fi

# Package upgrade information function with optional changelog
# Usage: apt-upgrade-info [-c|--changelog] [package_filter]
apt-upgrade-info() {
    local show_changelog=false
    local pkg_filter=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--changelog)
                show_changelog=true
                shift
                ;;
            *)
                pkg_filter="$1"
                shift
                ;;
        esac
    done
    
    local output=""
    local count=0
    
    # Color codes
    local BRIGHT_BLUE='\033[1;94m'
    local GREEN='\033[1;32m'
    local YELLOW='\033[1;33m'
    local CYAN='\033[1;36m'
    local RED='\033[1;31m'
    local MAGENTA='\033[1;35m'
    local DIM='\033[2m'
    local NC='\033[0m'
    
    # Check if there are any upgradable packages first
    if ! apt list --upgradable 2>/dev/null | grep -q '^[^W]'; then
        echo "No packages available for upgrade."
        return 0
    fi
    
    # Get list of upgradable packages, optionally filtered
    local pkg_list
    if [[ -n "$pkg_filter" ]]; then
        pkg_list=$(apt list --upgradable 2>/dev/null | tail -n +2 | cut -d'/' -f1 | grep -i "$pkg_filter")
    else
        pkg_list=$(apt list --upgradable 2>/dev/null | tail -n +2 | cut -d'/' -f1)
    fi
    
    if [[ -z "$pkg_list" ]]; then
        echo "No matching packages found."
        return 0
    fi
    
    for pkg in $pkg_list; do
        output+="\n${BRIGHT_BLUE}=== $pkg ===${NC}\n"
        
        # Get current and new versions
        local current_version=$(dpkg -l 2>/dev/null | grep "^ii  $pkg " | awk '{print $3}')
        local new_version=$(apt list --upgradable 2>/dev/null | grep "^$pkg/" | cut -d' ' -f2)
        
        if [[ -z "$current_version" ]]; then
            output+="${MAGENTA}Installing:${NC} ${GREEN}$new_version${NC}\n\n"
        else
            output+="${YELLOW}Upgrading:${NC} ${RED}$current_version${NC} ${CYAN}→${NC} ${GREEN}$new_version${NC}\n\n"
        fi
        
        # Get full description with colored first line
        local description=$(apt-cache show "$pkg" 2>/dev/null | sed -n '/^Description-en:/,/^[^ ]/p' | sed '$d' | sed 's/^Description-en: //' | sed 's/^ //')
        local first_line=$(echo "$description" | head -n1)
        local rest_lines=$(echo "$description" | tail -n +2)
        
        output+="${CYAN}$first_line${NC}\n"
        output+="$rest_lines\n"
        
        # Show changelog if requested and this is an upgrade (not new install)
        if [[ "$show_changelog" == true && -n "$current_version" ]]; then
            output+="\n${MAGENTA}Changelog:${NC}\n"
            
            # Fetch changelog and extract entries between versions
            # Format: package (version) distribution; urgency=...
            local changelog
            changelog=$(apt changelog "$pkg" 2>/dev/null | awk -v new="$new_version" -v cur="$current_version" '
                BEGIN { printing = 0 }
                # Match version header lines: package (version) distribution; urgency=...
                /^[^ ]+ \([^)]+\)/ {
                    # Extract version: find ( and ), take content between
                    start = index($0, "(")
                    end = index($0, ")")
                    if (start > 0 && end > start) {
                        ver = substr($0, start + 1, end - start - 1)
                        
                        if (ver == new) {
                            printing = 1
                        }
                        if (ver == cur) {
                            printing = 0
                            exit
                        }
                    }
                }
                printing { print }
            ')
            
            if [[ -n "$changelog" ]]; then
                # Indent and dim the changelog, limit to reasonable length
                output+="${DIM}$(echo "$changelog" | head -50 | sed 's/^/  /')${NC}\n"
                local total_lines=$(echo "$changelog" | wc -l)
                if [[ $total_lines -gt 50 ]]; then
                    output+="  ${DIM}... ($(($total_lines - 50)) more lines, use 'apt changelog $pkg' for full)${NC}\n"
                fi
            else
                output+="  ${DIM}(changelog not available or versions not found)${NC}\n"
            fi
        fi
        
        output+="\n"
        ((count++))
    done
    
    # Use less if more than 5 packages, otherwise print directly
    if [[ $count -gt 5 ]]; then
        echo -e "$output" | less -R
    else
        echo -e "$output"
    fi
}

alias aui='apt-upgrade-info'
alias auic='apt-upgrade-info -c'

cleanup() {
    echo "Cleaning package cache..."
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    echo "✓ Cleanup complete"
}

# SSH agent setup for passwordless git operations
ssh_setup() {
    # Start ssh-agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" >/dev/null
    fi
    
    # Add key if not already loaded
    if ! ssh-add -l >/dev/null 2>&1; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
    fi
}
