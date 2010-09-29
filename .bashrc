# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
#if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
#    debian_chroot=$(cat /etc/debian_chroot)
#fi

# set a fancy prompt (non-color, unless we know we "want" color)
#case "$TERM" in
#    xterm-color) color_prompt=yes;;
#esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

#if [ -n "$force_color_prompt" ]; then
#    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
#	# We have color support; assume it's compliant with Ecma-48
#	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
#	# a case would tend to support setf rather than setaf.)
#	color_prompt=yes
#    else
#	color_prompt=
#    fi
#fi

#if [ "$color_prompt" = yes ]; then
#    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#else
#    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
#fi
#unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
#    ;;
#*)
#    ;;
#esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

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

# Run the global /etc/bashrc, if it exists.

if [ -f "/etc/bashrc" ] ; then
    . /etc/bashrc
fi

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
        [ -e /etc/sysconfig/bash-prompt-default ] && PROMPT_COMMAND=/etc
/sysconfig/bash-prompt-default
        ;;
    esac
    # Turn on checkwinsize (already done above)
    #shopt -s checkwinsize
    [ "$PS1" = "\\s-\\v\\\$ " ] && PS1="[\u@\h \W]\\$ "
fi


# Fink environment setup
[ -r /sw/bin/init.sh ] && . /sw/bin/init.sh

# Pylab on banting setup
[ -r /opt/sw/pylab/path_setup.sh ] &&  . /opt/sw/pylab/path_setup.sh

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


if [ `uname -s` == 'Darwin' ] ; then
    # Define paths to stuff I use on one or more Macs.
    MACPYTHON_BIN="/Library/Frameworks/Python.framework/Versions/Current/bin"
    MACTEX_BIN="/usr/texbin"
    MYSQL_BIN="/usr/local/mysql/bin"
    
    # Add them to the path, if they exist.
    add_to_front_of_path "$MACPYTHON_BIN"
    add_to_front_of_path "$MACTEX_BIN"
    add_to_front_of_path "$MYSQL_BIN"
fi

# virtualenvwrapper stuff

VEW_BASHRC=`which virtualenvwrapper_bashrc 2>/dev/null`

if [ $VEW_BASHRC ] ; then
    mkdir -p $HOME/.virtualenvs
    export WORKON_HOME=$HOME/.virtualenvs
    source $VEW_BASHRC
fi

# New virtualenvwrapper script

VEW_SH=`which virtualenvwrapper.sh 2>/dev/null`

if [ $VEW_SH ] ; then
    mkdir -p $HOME/.virtualenvs
    export WORKON_HOME=$HOME/.virtualenvs
    source $VEW_SH
fi

# LISA specific stuff
if [ -e /opt/lisa/os/.local.bashrc ] ; then
    source /opt/lisa/os/.local.bashrc
elif [ -e /data/lisa/data/local_export/.local.bashrc ] ; then
    source /data/lisa/data/local_export/.local.bashrc
fi
if [ -e /opt/lisa/os/firefox-3.6/bin ] ; then
    add_to_front_of_path /opt/lisa/os/firefox-3.6/bin
fi
if [ -e $HOME/src/theano ] ; then
    export PYTHONPATH=$HOME/src/theano:$PYTHONPATH
fi
if [ -e $HOME/src/pylearn ] ; then
    export PYTHONPATH=$HOME/src/pylearn:$PYTHONPATH
fi

# Custom prompt settings
[ -r ~/.prompt.sh ]               && . ~/.prompt.sh

