# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================
HISTCONTROL=ignoreboth          # don't put duplicate lines or lines starting with space
HISTSIZE=10000                  # increased from 1000 for better history
HISTFILESIZE=20000              # increased from 2000
HISTTIMEFORMAT="%F %T "         # add timestamps to history
shopt -s histappend             # append to history file, don't overwrite
shopt -s histverify             # show command before executing from history

# ============================================================================
# SHELL OPTIONS
# ============================================================================
shopt -s checkwinsize           # update LINES and COLUMNS after each command
shopt -s cdspell                # minor errors in cd arguments will be corrected
shopt -s dirspell               # correct minor spelling errors in directory names
shopt -s globstar               # enable ** for recursive globbing

# make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ============================================================================
# PROMPT CONFIGURATION
# ============================================================================
# set variable identifying the chroot you work in
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
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
esac

# ============================================================================
# COLOR SUPPORT
# ============================================================================
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# ============================================================================
# LOAD ALIASES AND COMPLETIONS
# ============================================================================
# Load alias definitions from .bash_aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
# Better less defaults
export LESS='-R -i -w -M -z-4'

# Default editor
export EDITOR=vim
export VISUAL=vim

# Add local bin to PATH if it exists
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Add user bin to PATH if it exists
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

# GPG configuration for interactive shells
if [ -t 0 ]; then
    export GPG_TTY=$(tty)
fi

