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
    # Turn on checkwinsize
    shopt -s checkwinsize
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
    MACPORTS_BIN="/opt/local/bin"
    MACTEX_BIN="/usr/texbin"
    MYSQL_BIN="/usr/local/mysql/bin"
    MATLAB2009_BIN="/Applications/MATLAB_R2009a.app/bin"
    MATLAB2007_BIN="/Applications/MATLAB74/bin"
    
    # Add them to the path, if they exist.
    add_to_front_of_path "$MACPYTHON_BIN"
    add_to_front_of_path "$MACTEX_BIN"
    add_to_front_of_path "$MYSQL_BIN"
    add_to_front_of_path "$MACPORTS_BIN"
    add_to_front_of_path "$MATLAB2007_BIN"
    add_to_front_of_path "$MATLAB2009_BIN"
fi

# Machine specific aliases

case $HOSTNAME in 
    strafe*)
        MATLAB2009="/Applications/MATLAB_R2009a.app"
        #export DYLD_LIBRARY_PATH="$MATLAB2009/bin/maci"
        export MLABRAW_CMD_STR="$MATLAB2009/bin/matlab -nodesktop"
        ;;
    morrislab*)
        MATLAB2007="/Applications/MATLAB_R2007b"
        export DYLD_LIBRARY_PATH="$MATLAB2007/bin/mac"
        export MLABRAW_CMD_STR="$MATLAB2007/bin/matlab -nodesktop"
        ;;
    banting*)
        MATLAB2007B_BANTING="/opt/sw/matlab2007b/bin"
        add_to_front_of_path "$MATLAB2007B_BANTING"
        ;;
esac


