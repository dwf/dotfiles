#!/bin/bash

function install_script()
{
    if [ -r ~/"$1" ] ; then
        mv -v "$HOME/$1" "$HOME/$1.backup.`date |tr \" :\" \"__\"`"
    fi
    if [ \! -e "`dirname $1`" ] ; then
        mkdir -p "`dirname $1`"
    fi
    cp -v "./$1" "$HOME/$1"
}

install_script .bash_profile
install_script .bashrc
install_script .vimrc
install_script .prompt.sh
install_script .ssh/config
