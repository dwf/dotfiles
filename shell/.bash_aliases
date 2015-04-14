#!/bin/bash
if [[ $OSTYPE != darwin* ]]; then
    alias ls='ls --color=auto -F'
fi

# Colourize grep output.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ls shortcuts.
alias ll='ls -l'
alias lh='ls -sh'
alias la='ls -A'
alias l='ls -CF'

# Use the GPU easily with Theano.
alias gpu='THEANO_FLAGS=floatX=float32,device=gpu'
alias gpu0='THEANO_FLAGS=floatX=float32,device=gpu0'
alias gpu1='THEANO_FLAGS=floatX=float32,device=gpu1'
alias gpu2='THEANO_FLAGS=floatX=float32,device=gpu2'
alias gpu3='THEANO_FLAGS=floatX=float32,device=gpu3'

# Git fast-forward merge
alias gff='git merge --ff-only'

# Git fetch followed by
gfb() {
    set -x
    if [ -z $2 ]; then
        BASE_REMOTE_BRANCH='upstream/master'
    else
        BASE_REMOTE_BRANCH=$2
    fi
    if [ -z $3 ]; then
        PUSHLOC=origin
    else
        PUSHLOC=$3
    fi
    git fetch `echo $BASE_REMOTE_BRANCH|cut -d '/' -f 1`
    git checkout -b $1 $BASE_REMOTE_BRANCH && git push -u $PUSHLOC $1
    set +x
}
# Add the magical ability to have multiple ssh config files.

# Cribbed from the following site:
# http://www.linuxsysadmintutorials.com/multiple-ssh-client-configuration-files/
# with a small tweak to suppress output of the backgrounded process PID.

ssh() {
    case "$(uname -s)" in
        Linux)
            tmp_fifo=$(mktemp -u --suffix=._ssh_fifo)
            ;;
        Darwin)
            tmp_fifo=$(mktemp -u -t ._ssh_fifo)
            ;;
        *)
            echo 'unsupported OS'
            exit
            ;;
    esac

    # cleanup first
    # rm ~/tmp/._ssh_fifo* 2>/dev/null
    for fn in ~/tmp/._ssh_fifo*; do
        if [ ! -d $fn -a ! -d $fn.lock ]; then
            rm -f $fn
        fi
    done
    mkdir "$tmp_fifo.lock" >/dev/null 2>&1
    touch "$tmp_fifo"
    chmod 600 "$tmp_fifo"
    (cat ~/.ssh/config ~/.ssh/config.* >"$tmp_fifo" 2>/dev/null &)
    /usr/bin/ssh -F "$tmp_fifo" "$@"
    rm -rf "$tmp_fifo.lock"
    rm -f "$tmp_fifo"
}

_ssh_auth_save() {
    ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh-auth-sock.$HOSTNAME"
}
alias screen='_ssh_auth_save ; export HOSTNAME=$(hostname) ; screen'
alias tmux='_ssh_auth_save ; export HOSTNAME=$(hostname) ; tmux'

# Conda environment aliases.
alias sa='source activate'
alias sd='source deactivate'

# hub command for better GitHub integration.
[ $(which hub) ] && alias git=hub

# Force password authentication with SSH. Used to get around the situation
# where SSH freezes while trying to do public key authentication because
# DIRO has the NFS/Kerberos Setup From Hell.
# From http://unix.stackexchange.com/q/15138
alias sshpw='ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no'
