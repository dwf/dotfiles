# `nix run .#claude-vm` boots into Claude Code on whatever directory it's
# invoked from; `.#claude-vm-shell` drops to a debug shell in the same VM.
# Both point at the same already-wrapped commands (host-side per-project prep
# baked in - see ../lib.nix's `wrap`) that the home-manager `claude-vm` PATH
# wrapper (./wrappers.nix) installs, so there's exactly one sandbox config.
#
# Not tied to a real host (no home-manager config to source a hostName from
# - see ./wrappers.nix), so `hostName` here is just a placeholder guaranteed
# not to collide with a real metadata/hosts.nix entry, and
# allowImpureSshKeyFallback lets ../lib.nix trust whatever's in the invoking
# user's ~/.ssh instead - only under `nix run --impure`; a plain `nix run`
# fails loudly (Nix's own pure-eval check on reading ~/.ssh, before ours).
{
  inputs,
  pkgs,
  system,
}:
let
  sandbox = import ./sandbox.nix {
    inherit inputs pkgs system;
    hostName = "nix-run";
    allowImpureSshKeyFallback = true;
  };
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
