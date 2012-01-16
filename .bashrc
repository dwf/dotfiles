# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# Run the global /etc/bashrc, if it exists.

if [ -f "/etc/bashrc" ] ; then
    . /etc/bashrc
elif [ -f "/etc/bash.bashrc" ] ; then
    . /etc/bash.bashrc
fi

# Function to conditionally add a directory to the front of the PATH
# if the directory exists.
function add_to_front_of_path()
{
    if [ -x "$1" ] ; then
        PATH="$1:$PATH"
    fi
}

# Home directory binaries ~/bin
add_to_front_of_path "$HOME/bin"

# ~/sw/bin is something I use a lot too
add_to_front_of_path "$HOME/sw/bin"

# ~/sw/bin is something I use a lot too
add_to_front_of_path "$HOME/.local/bin"

VEW_SH=`which virtualenvwrapper.sh 2>/dev/null`

if [ $VEW_SH ] ; then
    mkdir -p $HOME/.virtualenvs
    export WORKON_HOME=$HOME/.virtualenvs
    source $VEW_SH
fi

# Environment-specific setup
if [ `uname -s` == 'Darwin' ] ; then
    [ -e "$HOME/.bashrc-macosx" ] && . $HOME/.bashrc-macosx
fi

# LISA-specific aliases, path setup, etc.
[ -e $HOME/.bashrc-lisa ] && . $HOME/.bashrc-lisa

# Machine-specific files
[ -e $HOME/.bashrc.`hostname -s` ] && . $HOME/.bashrc.`hostname -s`

# If not running interactively, don't do anything past this point
[ -z "$PS1" ] && return

############################# INTERACTIVE SETUP #############################

# force ignoredups and ignorespace
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

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
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# git bash completion
[ -r ~/.git-bash-completion.sh ]  && . ~/.git-bash-completion.sh

# This logic stolen from the Red Hat /etc/bashrc.

if [ "$PS1" ]; then
    case $TERM in
    xterm*)
        if [ -e /etc/sysconfig/bash-prompt-xterm ]; then
            PROMPT_COMMAND=/etc/sysconfig/bash-prompt-xterm
        else
            PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}"; echo -ne "\007"'
        fi
        ;;
    screen)
        if [ -e /etc/sysconfig/bash-prompt-screen ]; then
            PROMPT_COMMAND=/etc/sysconfig/bash-prompt-screen
        else
        PROMPT_COMMAND='echo -ne "\033_${USER}@${HOSTNAME%%.*}:${PWD/#$H
OME/~}"; echo -ne "\033\\"'
        fi
        ;;
    *)
        [ -e /etc/sysconfig/bash-prompt-default ] && PROMPT_COMMAND=/etc/sysconfig/bash-prompt-default
        ;;
    esac
    # Turn on checkwinsize (already done above)
    #shopt -s checkwinsize
    [ "$PS1" = "\\s-\\v\\\$ " ] && PS1="[\u@\h \W]\\$ "
fi

# Custom prompt settings
[ -r ~/.prompt.sh ] && . ~/.prompt.sh
