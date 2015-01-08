# If ls hasn't been already aliased (i.e. by OS X conditional script)
# assume we're working with GNU ls.
alias ls >/dev/null 2>&1 && alias ls='ls --color=auto -F'

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
