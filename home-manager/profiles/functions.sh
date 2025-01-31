# run zsh inside `nix develop`.
nix() {
  if [[ $1 == "dev" ]]; then
    shift
    command nix develop -c "$SHELL" "$@"
  else
    command nix "$@"
  fi
}
