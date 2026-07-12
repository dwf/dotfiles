# home-manager module: the `claude-vm` PATH wrapper for the agentspace microVM.
# Sets AGENTSPACE_CWD so the impure ./apps.nix eval keys per-project history, then
# runs the flake app. A real command, so usable from a sidekick.nvim pane. A bare
# `nix run .#claude-vm` still works but shares one /mnt/cwd bucket.
{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "claude-vm" ''
      exec env AGENTSPACE_CWD="$PWD" nix run --impure /home/dwf/src/dotfiles#claude-vm
    '')
  ];
}
