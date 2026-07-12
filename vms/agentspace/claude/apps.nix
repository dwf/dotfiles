# `nix run .#claude-vm` boots into Claude Code on whatever directory it's
# invoked from; `.#claude-vm-shell` drops to a debug shell in the same VM.
# Both point at the same already-wrapped commands (host-side per-project prep
# baked in - see ../lib.nix's `wrap`) that the home-manager `claude-vm` PATH
# wrapper (./wrappers.nix) installs, so there's exactly one sandbox config.
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
    program = "${sandbox.agent}/bin/claude-vm";
  };
  claude-vm-shell = {
    type = "app";
    program = "${sandbox.shell}/bin/claude-vm-shell";
  };
}
