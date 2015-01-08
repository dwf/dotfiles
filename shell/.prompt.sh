#--------------------------------------------------------------------------
#
# Copyright (c) 2009 David Warde-Farley.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#--------------------------------------------------------------------------
# 
# Colour the prompt differently based on where you are logged in. Useful 
# for shared home directory situations or if you have a habit of forgetting
# which machine you're logged into and issuing the wrong commands in the 
# wrong window.
#
# By David Warde-Farley, April 26, 2009.
#
# To invoke this script so that environment variables stick, use 
# source <filename>.
#
# I recommend naming this script e.g. ~/.prompt.sh and putting it in
# .bash_profile as follows:
#
#   [ -f ~/.prompt.sh ] && . ~/.prompt.sh
#
#--------------------------------------------------------------------------


# Give names to "normal" colours
NORMAL_RED="0;31"
NORMAL_GREEN="0;32"
NORMAL_YELLOW="0;33"
NORMAL_BLUE="0;34"
NORMAL_MAGENTA="0;35"
NORMAL_CYAN="0;36"
NORMAL_WHITE="0;37"
NORMAL_RESET="0;38"

# Give names to "bright" colours
BRIGHT_RED="1;31"
BRIGHT_GREEN="1;32"
BRIGHT_YELLOW="1;33"
BRIGHT_BLUE="1;34"
BRIGHT_MAGENTA="1;35"
BRIGHT_CYAN="1;36"
BRIGHT_WHITE="1;37"
BRIGHT_RESET="1;38"

# underlined colors
UNDERLINE_BLACK="4;30"
UNDERLINE_RED="4;31"
UNDERLINE_GREEN="4;32"
UNDERLINE_YELLOW="4;33"
UNDERLINE_BLUE="4;34"
UNDERLINE_MAGENTA="4;35"
UNDERLINE_CYAN="4;36"
UNDERLINE_WHITE="4;37"

# background colors
BACKGROUND_BLACK='\e[40m'
BACKGROUND_RED='\e[41m'
BACKGROUND_GREEN='\e[42m'
BACKGROUND_YELLOW='\e[43m'
BACKGROUND_BLUE='\e[44m'
BACKGROUND_MAGENTA='\e[45m'
BACKGROUND_CYAN='\e[46m'
BACKGROUND_WHITE='\e[47m'

# Switch on $HOSTNAME. You could also switch on `hostname` I guess.

case $HOSTNAME in
    rodimus*)   # my mail/file server at home
        TEXT_COLOR="$NORMAL_GREEN"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    strafe*)    # my MacBook Pro
        TEXT_COLOR="$NORMAL_CYAN"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    morrislab*)    # my Mac at work
        TEXT_COLOR="$NORMAL_YELLOW"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    descartes*) # descartes head node
        TEXT_COLOR="$NORMAL_MAGENTA"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    dn*)        # descartes worker nodes
        TEXT_COLOR="$NORMAL_MAGENTA"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    banting*)   # banting head node
        TEXT_COLOR="$NORMAL_RED"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    node*)      # banting worker nodes
        TEXT_COLOR="$NORMAL_RED"
        SEP_COLOR="$NORMAL_BLUE"
        ;;
    barricade*)
        TEXT_COLOR="$NORMAL_CYAN"
	SEP_COLOR="$BRIGHT_MAGENTA"
	;;
    *)          # any other configuration
        TEXT_COLOR="$NORMAL_RESET"
        SEP_COLOR="$NORMAL_RESET"
        ;;
esac
    

PS1="\[\033[${TEXT_COLOR}m\]\u\[\033[${SEP_COLOR}m\]@\[\033[${TEXT_COLOR}m\]\h\[\033[${SEP_COLOR}m\]:\[\033[${TEXT_COLOR}m\]\w\[\033[${SEP_COLOR}m\]\$\[\033[${NORMAL_COLORS};${RESET_COLOR}m\] "
export PS1

