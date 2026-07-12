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

# Print the sha256 narHash for a GitHub repo, optionally at a given
# rev/branch/tag - for pinning pkgs.fetchFromGitHub / flake inputs without a
# fetch-then-fix-the-hash round trip. Usage: github-narhash owner/repo [rev]
#
# builtins.fetchTree's github fetcher (unlike pkgs.fetchFromGitHub's more
# permissive `rev`) distinguishes `rev` (a full 40-char commit sha) from
# `ref` (branch/tag name) - reject the former outright rather than trying to
# resolve it as a ref. Detect which one was given rather than making the
# caller know the difference.
function github-narhash() {
  local owner=${1%%/*} repo=${1#*/}
  if [[ -z $1 || -z $owner || -z $repo || $owner == "$1" ]]; then
    echo "usage: github-narhash owner/repo [rev]" >&2
    return 1
  fi
  local revAttr=""
  if [[ -n $2 ]]; then
    if [[ $2 =~ ^[0-9a-f]{40}$ ]]; then
      revAttr="rev = \"$2\";"
    else
      revAttr="ref = \"$2\";"
    fi
  fi
  # --raw prints the string with no trailing newline, which zsh flags with an
  # inverted `%` before the next prompt - capture and re-emit with one.
  local hash
  hash=$(
    nix eval --impure --raw --expr \
      "(builtins.fetchTree { type = \"github\"; owner = \"$owner\"; repo = \"$repo\"; $revAttr }).narHash"
  ) || return
  printf '%s\n' "$hash"
}
