# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    #alias grep='grep --color=auto'
    #alias fgrep='fgrep --color=auto'
    #alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -l'
#alias la='ls -A'
#alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Customizations ----------------------------------------------------

# ls options doesn't allow for the sorting I want, so using AWK here.
# Inspired by https://github.com/RichardBronosky/dotfiles
# and https://stackoverflow.com/a/51141872/2271042
eval 'function l(){ ls -Ahl --color=always $* | awk -f ~/.ls.awk; }'

if command -v kubectl 2>&1 >/dev/null
then
  alias k='kubectl'
  complete -F __start_kubectl k

  # set the copied k3s config as KUBECONFIG, so that sudo is not necessary to run kubectl
  # see https://github.com/k3s-io/k3s/issues/389#issuecomment-745808339
  export KUBECONFIG=~/.kube/k3s-config
fi

# Set GPG_TTY for interactive shells to allow password prompts on the console
if [ -t 0 ]; then
  export GPG_TTY=$(tty)
fi

apt-upgrade-info() {
  local output=""
  local count=0
  
  for pkg in $(apt list --upgradable 2>/dev/null | tail -n +2 | cut -d'/' -f1); do
    # Color codes
    BRIGHT_BLUE='\033[1;94m'
    GREEN='\033[1;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[1;36m'
    RED='\033[1;31m'
    MAGENTA='\033[1;35m'
    NC='\033[0m' # No Color
    
    output+="\n${BRIGHT_BLUE}=== $pkg ===${NC}\n"
    
    # Get current and new versions
    current_version=$(dpkg -l 2>/dev/null | grep "^ii  $pkg " | awk '{print $3}')
    new_version=$(apt list --upgradable 2>/dev/null | grep "^$pkg/" | cut -d' ' -f2)
    
    if [ -z "$current_version" ]; then
      output+="${MAGENTA}Installing:${NC} ${GREEN}$new_version${NC}\n\n"
    else
      output+="${YELLOW}Upgrading:${NC} ${RED}$current_version${NC} ${CYAN}→${NC} ${GREEN}$new_version${NC}\n\n"
    fi
    
    # Get full description with colored first line
    description=$(apt-cache show $pkg | sed -n '/^Description-en:/,/^[^ ]/p' | sed '$d' | sed 's/^Description-en: //' | sed 's/^ //')
    first_line=$(echo "$description" | head -n1)
    rest_lines=$(echo "$description" | tail -n +2)
    
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