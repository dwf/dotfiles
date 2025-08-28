#!/bin/bash
# Frontend for wakeonlan, use as wol <host>, or no args to bring up fzf UI
HOSTSFILE=".wakeonlan-hosts"  # hostname\tmacaddr\tip\tdescription
BINARY=$([ -e "@wakeonlan@" ] && echo "@wakeonlan@" || echo "wakeonlan") # Fall back on "wakeonlan" to make this script portable outside of nix deployment
PINGWAIT=0.25
MAXHEIGHT=10
if [ "$#" == 0 ]; then
  if [ -f "$HOME/$HOSTSFILE" ]; then
    NUMHOSTS=$(cat "$HOME/$HOSTSFILE" | wc -l)
    HEIGHT=$(("$NUMHOSTS" <= "$MAXHEIGHT" ? "$NUMHOSTS" : "$MAXHEIGHT"))
    {
      echo -e "STATUS\tHOSTNAME\tMAC\tIP\tDESCRIPTION"
      while IFS=$'\t' read -r hostname mac ip description; do
        echo -e "  $(ping -c 1 -W "$PINGWAIT" "$ip" &>/dev/null && printf '\033[32m●\033[0m' || printf '\033[31m●\033[0m')\t\033[1m$hostname\033[0m\t\033[90m$mac\t$ip\033[0m  \t$description"
      done < "$HOME/$HOSTSFILE"
    } | column -t -s $'\t' | fzf --ansi --header-lines=1 --reverse --height "$(($HEIGHT + 3))" --highlight-line | awk '{print $3}' | xargs -I '{}' sh -c "[ -n {} ] && $BINARY {}"
  else
    echo "error: no host configuration found at ~/$HOSTSFILE" && exit 1
  fi
else
  while [ "$#" != 0 ]; do
    macaddr=$(grep "^$1	" "$HOSTSFILE" | cut -f 2)
    [ -n "$macaddr" ] && wakeonlan "$macaddr" || {
      echo "error: '$1' not found in ~/$HOSTSFILE" && exit 1
    }
    shift
  done
fi
