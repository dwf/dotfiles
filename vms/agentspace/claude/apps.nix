# `nix run .#claude-vm` boots into Claude Code on whatever directory it's
# invoked from; `.#claude-vm-shell` drops to a debug shell in the same VM.
# Both are thin wrappers around the shared, purely-built sandbox definition
# in ./sandbox.nix - the same derivations the home-manager `claude-vm` PATH
# wrapper (./wrappers.nix) uses, so there's exactly one sandbox config.
{
  inputs,
  pkgs,
  system,
}:
let
  sandbox = import ./sandbox.nix { inherit inputs pkgs system; };
in
{
  claude-vm = {
    type = "app";
    program = sandbox.claude;
  };
  claude-vm-shell = {
    type = "app";
    program = sandbox.shell;
  };
}
