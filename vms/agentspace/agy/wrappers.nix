# home-manager module: installs the `agy-vm` PATH command for the
# agentspace microVM running antigravity-cli (`agy`). The command itself -
# including the host-side per-project prep (repointing the `workspace`
# symlink at $PWD, writing the tag/argv into `meta`) - is built once in
# ../lib.nix's `wrap`, shared with the `nix run .#agy-vm` flake app
# (./apps.nix), so both entry points behave identically.
{ pkgs, inputs, ... }:
let
  sandbox = import ./sandbox.nix {
    inherit inputs pkgs;
    system = pkgs.system;
  };
in
{
  home.packages = [ sandbox.agent ];
}
