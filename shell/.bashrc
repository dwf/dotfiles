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
function front_of_path()
{
    if [ -x "$1" ] ; then
        PATH="$1:$PATH"
    fi
}

# Home directory binaries ~/bin
front_of_path "$HOME/bin"

# ~/sw/bin is something I use a lot too
front_of_path "$HOME/sw/bin"

if [[ "$OSTYPE" == "linux-gnu*" ]]; then
    # Linux tends to store some stuff in there.
    front_of_path "$HOME/.local/bin"
fi

for script in ~/.bashrc.d/site/*; do
    . $script
done

# If not running interactively, don't do anything past this point
[ -z "$PS1" ] && return

# Run the interactive-specific setup.
[ -f ~/.bashrc.interactive ] && . ~/.bashrc.interactive
