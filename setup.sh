#!/bin/sh

OLDPWD=`pwd`
SCRIPTPWD=`cd \`dirname "$0"\` && pwd`

install_dotfile() {
    # If there's a regular file there, make a backup 
    if [ -f "$HOME/$1" -a \! -L "$HOME/$1" ] ; then
        mv "$HOME/$1" "$HOME/$1.backup"
    fi
    if [ \! -e "$HOME/`dirname $1`" ] ; then
        mkdir -v -p "$HOME/`dirname $1`"
    fi
    # If there is no symlink yet, then link it already.
    if [ \! -e "$HOME/$1" ] ; then
        echo -n 'Symlinking: '
        ln -v -s "$SCRIPTPWD/$1" "$HOME/$1"
    fi
}

# Bash configuration
install_dotfile .bash_profile
install_dotfile .bashrc

# Git-related
install_dotfile .git-completion.bash
install_dotfile .gitconfig

# Prompt colouring
install_dotfile .prompt.sh

# Settings for GNU screen
install_dotfile .screenrc

# ssh configuration
install_dotfile .ssh/config

# Plugins bindings for vim
install_dotfile .vim/ftplugin/python.vim
install_dotfile .vim/indent/python.vim
install_dotfile .vim/ftplugin/opencl.vim
install_dotfile .vim/ftdetect/opencl.vim
install_dotfile .vim/indent/opencl.vim
install_dotfile .vim/syntax/opencl.vim

# Global settings for vim
install_dotfile .gvimrc
install_dotfile .vimrc
