# run zsh inside `nix develop`.
nix() {
  if [[ $1 == "dev" ]]; then
    shift
    command nix develop -c "$SHELL" "$@"
  else
    command nix "$@"
  fi
}

# Launch an ipython shell with latest nixpkgs unstable. Optionally, arguments
# add libraries to the Python environment.
function ipy() {
  nix shell --impure --expr "with (builtins.getFlake \"nixpkgs\").legacyPackages.\${builtins.currentSystem}; python3.withPackages (ps: with ps; [ ipython $*])" -c ipython
}
