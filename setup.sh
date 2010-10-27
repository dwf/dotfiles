#!/bin/bash

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
install_dotfile .vim/ftplugin/pyrex.vim
install_dotfile .vim/indent/python.vim
install_dotfile .vim/ftplugin/opencl.vim
install_dotfile .vim/ftdetect/opencl.vim
install_dotfile .vim/indent/opencl.vim
install_dotfile .vim/syntax/opencl.vim
install_dotfile .vim/syntax/python.vim
install_dotfile .vim/syntax/pyrex.vim
install_dotfile .vim/ftdetect/f2py.vim
install_dotfile .vim/ftplugin/python/fold.vim
install_dotfile .vim/ftplugin/python/pyflakes.vim
install_dotfile .vim/ftplugin/python/pyflakes/bin/pyflakes
install_dotfile .vim/ftplugin/python/pyflakes/LICENSE
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/__init__.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/ast.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/checker.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/messages.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/scripts/__init__.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/scripts/pyflakes.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/test/__init__.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/test/harness.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/test/test_imports.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/test/test_other.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/test/test_script.py
install_dotfile .vim/ftplugin/python/pyflakes/pyflakes/test/test_undefined_names.py
install_dotfile .vim/ftplugin/python/pyflakes/README.rst
install_dotfile .vim/ftplugin/python/pyflakes/setup.py
install_dotfile .vim/ftplugin/python/pyflakes/TODO

# snipMate.
install_dotfile .vim/after/plugin/snipMate.vim
install_dotfile .vim/autoload/snipMate.vim
install_dotfile .vim/doc/snipMate.txt
install_dotfile .vim/ftplugin/html_snip_helper.vim
install_dotfile .vim/plugin/snipMate.vim
install_dotfile .vim/snippets/autoit.snippets
install_dotfile .vim/snippets/c.snippets
install_dotfile .vim/snippets/cpp.snippets
install_dotfile .vim/snippets/html.snippets
install_dotfile .vim/snippets/java.snippets
install_dotfile .vim/snippets/javascript.snippets
install_dotfile .vim/snippets/mako.snippets
install_dotfile .vim/snippets/objc.snippets
install_dotfile .vim/snippets/perl.snippets
install_dotfile .vim/snippets/php.snippets
install_dotfile .vim/snippets/python.snippets
install_dotfile .vim/snippets/ruby.snippets
install_dotfile .vim/snippets/sh.snippets
install_dotfile .vim/snippets/snippet.snippets
install_dotfile .vim/snippets/tcl.snippets
install_dotfile .vim/snippets/tex.snippets
install_dotfile .vim/snippets/vim.snippets
install_dotfile .vim/snippets/zsh.snippets
install_dotfile .vim/syntax/snippet.vim

# Global settings for vim
install_dotfile .gvimrc
install_dotfile .vimrc

# hg
install_dotfile .hgrc
