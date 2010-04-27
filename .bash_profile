# git bash completion
[ -r ~/.git-bash-completion.sh ]  && . ~/.git-bash-completion.sh

# Execute .bashrc
[ -r ~/.bashrc  ]                 &&. ~/.bashrc

# Platform specific aliases, definitions, etc.

if [ `uname -s` == 'Darwin' ] ; then
    alias lsrebuild="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user"
    function quitapp()
    {
    echo "tell application \"$1\"
    quit
    end tell" |osascript
    }
    # Enable colorized output on OS X
    alias ls='ls -G'
    alias la='ls -AG'
    
    # Alias 'md5' to 'md5sum' since I still make this mistake
    alias md5sum='md5'
fi
