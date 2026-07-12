# `nix run .#agy-vm` boots into antigravity-cli (`agy`) on whatever directory
# it's invoked from; `.#agy-vm-shell` drops to a debug shell in the same VM.
# Both point at the same already-wrapped commands (host-side per-project prep
# baked in - see ../lib.nix's `wrap`) that the home-manager `agy-vm` PATH
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
  agy-vm = {
    type = "app";
    program = "${sandbox.agent}/bin/agy-vm";
  };
  agy-vm-shell = {
    type = "app";
    program = "${sandbox.shell}/bin/agy-vm-shell";
  };
}
