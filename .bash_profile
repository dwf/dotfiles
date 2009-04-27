# Fink environment setup
[ -r /sw/bin/init.sh ]            && . /sw/bin/init.sh

# git bash completion
[ -r ~/.git-bash-completion.sh ]  && . ~/.git-bash-completion.sh

# Execute .bashrc
[ -r ~/.bashrc  ]                 &&. ~/.bashrc

# Custom prompt settings
[ -r ~/.prompt.sh ]               && . ~/.prompt.sh

# Platform specific aliases, definitions, etc.

if [ `uname -s` == 'Darwin' ] ; then
    alias lsrebuild="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"
    function quitapp()
    {
    echo "tell application \"$1\"
    quit
    end tell" |osascript
    }
fi