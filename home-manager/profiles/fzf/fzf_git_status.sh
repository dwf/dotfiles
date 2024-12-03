#!/usr/bin/env bash

if ! git rev-parse HEAD > /dev/null 2>&1; then
  [[ -n $TMUX ]] && tmux display-message "Not in a git repository"
  exit 1
fi

_boxes=@boxes@/bin/boxes
_bat=@bat@/bin/bat
_eza=@eza@/bin/eza
_fzf=@fzf@/bin/fzf
_git=@git@/bin/git
# shellcheck disable=SC2016
_GET_FILENAME_AWK='BEGIN { FPAT = "([^ ]+)|(\"[^\"]+\")" }; {print $2}'

# Borrowed from fzf-git.sh
__fzf_git_pager() {
  local pager
  pager="${FZF_GIT_PAGER:-${GIT_PAGER:-$(git config --get core.pager 2>/dev/null)}}"
  echo "${pager:-cat}"
}

# Ported to zsh from PatrickF1/fzf-fish
if [ -t 1 ] && [ $# -eq 0 ]; then
   $_git -c status.color=always status --short | \
     $_fzf \
     --border-label "Git Status" \
     --header $'CTRL-D (diffs) / ALT-E (examine in editor)\n\n' \
     --ansi \
     --multi \
     --preview "$0 {}" \
     --min-height=20 \
     --height=80% \
     --reverse \
     --nth="2.." \
     --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
     --bind "ctrl-d:execute:$0 {} | less > /dev/tty" \
     --min-height=20 --border \
     --border-label-pos=2 \
     --color='header:italic:underline,label:blue' \
     --preview-window='right,50%,border-left' \
     --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' | \
     awk "$_GET_FILENAME_AWK" | \
     tr '\n' ' ' |sed -e 's/ $/\n/'
  exit
fi

function dir_preview() {
  $_eza -F --group-directories-first --icons --color=always "$1"
}
function file_preview() {
  $_bat --color=always "$1"
}
function git_diff() {
  $_git diff --color=always -- "$@" | eval "$(__fzf_git_pager)"
}
function diff_header() {
  # \e[33m for yellow, \e[0m resets
  printf "\e[33m%s\e[0m\n" "$(echo "$1" | $_boxes -d ansi)"
}

index_status=${1:0:1}
working_status=${1:1:1}
path="$(echo "$1" | awk "$_GET_FILENAME_AWK" |xargs echo)"

if [ "$index_status" == "?" ]; then
  diff_header Untracked
  if [ -d "$path" ]; then
    dir_preview "$path"
  else
    file_preview "$path"
  fi
elif echo "DD AU UD UA DU AA UU" | grep -w -q "${1:0:2}"; then
  diff_header Unmerged
  git_diff "$path"
else
  if [ "$index_status" != " " ]; then
    diff_header Staged
    if [ "$index_status" == "R" ]; then
      renamed_path="$(echo "$1" | awk 'BEGIN { FPAT = "([^ ]+)|(\"[^\"]+\")" }; {print $4}' |xargs echo)"
      git_diff --staged "$path" "$renamed_path"
    else
      git_diff --staged "$path"
    fi
  fi
  if [ "$working_status" != " " ]; then
    diff_header Unstaged
    git_diff "$path"
  fi
fi
