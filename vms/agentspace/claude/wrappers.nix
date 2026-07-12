# home-manager module: the `claude-vm` PATH wrapper for the agentspace microVM.
# Builds the same sandbox derivation as ./apps.nix (see ./sandbox.nix for why
# this no longer needs `nix run`/`--impure`), then at *invocation* time - plain
# runtime bash, no Nix eval involved - repoints the fixed `workspace` symlink at
# $PWD, writes a per-project tag into the fixed `meta` dir, and forwards
# whatever `claude-vm` was called with straight through to `claude` inside the
# guest (e.g. `claude-vm --resume`, `--continue`, a search term), before
# exec'ing the pre-built launch program. A real command, so usable from a
# sidekick.nvim pane.
#
# Args can't be passed as CLI args to the launch program itself: mkLaunch's
# generated script special-cases nonzero argc to replace the whole configured
# ssh remote command with "$@" verbatim, which would skip the cd/bind-mount
# preamble entirely. So they go through the same fixed-path/runtime-rewrite
# trick as the tag - newline-separated into the `meta` share's `args` file -
# which the guest script reads back (see sandbox.nix).
{ pkgs, inputs, ... }:
let
  sandbox = import ./sandbox.nix {
    inherit inputs pkgs;
    system = pkgs.system;
  };
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "claude-vm" ''
      set -euo pipefail
      tag="$(basename "$PWD")-$(printf '%s' "$PWD" | sha256sum | cut -c1-8)"
      mkdir -p "$(dirname ${sandbox.workspaceLink})" ${sandbox.metaDir}
      ln -sfn "$PWD" ${sandbox.workspaceLink}
      printf '%s' "$tag" > ${sandbox.metaDir}/tag
      printf '%s\n' "$@" > ${sandbox.metaDir}/args
      exec ${sandbox.claude}
    '')
  ];
}
