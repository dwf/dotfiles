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
alias gpu4='THEANO_FLAGS=floatX=float32,device=gpu4'
alias gpu5='THEANO_FLAGS=floatX=float32,device=gpu5'
alias gpu6='THEANO_FLAGS=floatX=float32,device=gpu6'
alias gpu7='THEANO_FLAGS=floatX=float32,device=gpu7'

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
    if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "----------------------------------------------"
        echo " SSH_AUTH_SOCK not set, can't fix up symlink."
        echo "----------------------------------------------"
        sleep 0.8
    else
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/ssh-auth-sock.$HOSTNAME"
    fi
}
# alias screen='_ssh_auth_save ; export HOSTNAME=$(hostname) ; screen'
# alias tmux='_ssh_auth_save ; export HOSTNAME=$(hostname) ; tmux'

# Conda environment aliases.
alias sa='source activate'
alias sd='source deactivate'

# hub command for better GitHub integration.
[ $(which hub 2>/dev/null) ] && alias git=hub

# Force password authentication with SSH. Used to get around the situation
# where SSH freezes while trying to do public key authentication because
# DIRO has the NFS/Kerberos Setup From Hell.
# From http://unix.stackexchange.com/q/15138
alias sshpw='ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no'
ssht() {
    if [ $# == 1 ]; then
        if [ -z "$DEFAULT_SSH_PROXY_HOST" ]; then
            echo "No DEFAULT_SSH_PROXY_HOST set and none specified."
            return 1
        else
            ssh -t $DEFAULT_SSH_PROXY_HOST ssh $1
        fi
    elif [ $# == 2 ]; then
        ssh -t $1 ssh $2
    fi
}

sshf() {
    if [ $# -lt 2 ]; then
        echo "usage: sshf host [port|local:remote] [[port|local:remote] ...]"
        return 1
    fi
    SSH_ARGS="$1"
    shift
    while (( "$#" )); do
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            SSH_ARGS="$SSH_ARGS -L $1:localhost:$1"
        elif [[ "$1" =~ ^[0-9]+:[0-9]+$ ]]; then
            SSH_ARGS="$SSH_ARGS -L $(echo $1|cut -d ':' -f 1):localhost:$(echo $1|cut -d ':' -f 2)"
        else
            echo "usage: sshf host [port|local:remote] [[port|local:remote] ...]"
            return 1
        fi
        shift
    done
    echo ssh $SSH_ARGS
    ssh $SSH_ARGS
}

sshft() {
    if [ $# -lt 2 ]; then
            echo "usage: sshft host [port|local:remote|local:bridge:remote] ...]"
        return 1
    fi
    if [ -z "$DEFAULT_SSH_PROXY_HOST" ]; then
        echo "No DEFAULT_SSH_PROXY_HOST set."
        return 1
    fi
    FIRST_SSH_ARGS="$DEFAULT_SSH_PROXY_HOST"
    SECOND_SSH_ARGS="$1"
    shift
    while (( "$#" )); do
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            FIRST_SSH_ARGS="$FIRST_SSH_ARGS -L $1:localhost:$1"
            SECOND_SSH_ARGS="$SECOND_SSH_ARGS -L $1:localhost:$1"
        elif [[ "$1" =~ ^[0-9]+:[0-9]+$ ]]; then
            FIRST_PORT=$(echo $1 |cut -d ':' -f 1)
            SECOND_PORT=$(echo $1 |cut -d ':' -f 2)
            FIRST_SSH_ARGS="$FIRST_SSH_ARGS -L $FIRST_PORT:localhost:$FIRST_PORT"
            SECOND_SSH_ARGS="$SECOND_SSH_ARGS -L $FIRST_PORT:localhost:$SECOND_PORT"
        elif [[ "$1" =~ ^[0-9]+:[0-9]:[0-9]+$ ]]; then
            FIRST_PORT=$(echo $1 |cut -d ':' -f 1)
            SECOND_PORT=$(echo $1 |cut -d ':' -f 2)
            THIRD_PORT=$(echo $1 |cut -d ':' -f 3)
            FIRST_SSH_ARGS="$FIRST_SSH_ARGS -L $FIRST_PORT:localhost:$SECOND_PORT"
            SECOND_SSH_ARGS="$SECOND_SSH_ARGS -L $SECOND_PORT:localhost:$THIRD_PORT"

        else
            echo "usage: sshft host [port|local:remote|local:bridge:remote] ...]"
            return 1
        fi
        shift
    done
    echo ssh $FIRST_SSH_ARGS -t ssh $SECOND_SSH_ARGS
    ssh $FIRST_SSH_ARGS -t ssh $SECOND_SSH_ARGS
}

# Quick and dirty installation of packages with pip from GitHub.
ghpip() {
    if [ $# == 0 ]; then
        echo "usage: ghpip user/project [branch/refspec]"
        return 1
    fi
    if [ $# == 1 ]; then
        GITHUBPATH=$1
        BRANCH=master
    else
        GITHUBPATH=$1
        BRANCH=$2
    fi
    pip install --upgrade "git+git://github.com/$GITHUBPATH.git@$BRANCH"
}
