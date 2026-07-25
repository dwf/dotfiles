# AI coding CLIs from the editor. `claude` is pointed at the `claude-vm`
# wrapper (see vms/agentspace/claude/wrappers.nix) instead of a bare `claude`
# binary, so `<leader>ac` launches Claude Code sandboxed in the agentspace
# microVM rather than running unsandboxed on the host (`<leader>aa` toggles
# whichever tool is already attached, or opens a picker if none is). The
# `antigravity` tool (Google Antigravity's `agy` CLI, see
# vms/agentspace/agy/wrappers.nix) gets the same `cmd` override, on top of a
# pinned plugin source - see `package` below, since its built-in tool config
# isn't in the nixpkgs-pinned release yet.
{ lib, pkgs, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    # sidekick-nvim's nixpkgs derivation links in copilot-language-server as a
    # runtimeDep unconditionally, even though NES/Copilot is disabled in our
    # settings (neovim/plugins/sidekick.nix). Stub it out rather than
    # allowing unfree wholesale: nothing calls it with NES off.
    nixpkgs.overlays = [
      (_: prev: {
        copilot-language-server = prev.emptyDirectory;
      })
    ];

    # sidekick.nvim ships a root-level `sk/cli/*.lua` directory (per-tool CLI
    # defaults, e.g. `cmd`), not under a standard runtime subdir. The combined
    # plugin pack (see ./performance.nix) only links standard dirs, so it
    # drops `sk/` -- every tool's `base[name]` lookup then comes back empty,
    # leaving `cmd` nil and crashing `sidekick.cli`. Keep it out of the pack.
    # Upstream: https://github.com/nix-community/nixvim/issues/4482
    performance.combinePlugins.standalonePlugins = [ "sidekick.nvim" ];

    plugins.sidekick = {
      enable = true;
      # Pin to folke/sidekick.nvim#322 (mateuszsip's `feat/agy-cli` branch),
      # open but unmerged as of 2026-07-12, which adds `sk/cli/antigravity.lua`
      # (a built-in tool config, name "antigravity", for Google Antigravity's
      # `agy` CLI) - the nixpkgs-pinned release predates it. Only `src` is
      # swapped, so the rest of the derivation (build phases, `pname`) is
      # still what nixpkgs built, and ./performance.nix's `standalonePlugins`
      # name match above still applies. Drop this override once the PR
      # merges and lands in a nixpkgs update.
      package = pkgs.vimPlugins.sidekick-nvim.overrideAttrs (_: {
        src = pkgs.fetchFromGitHub {
          owner = "mateuszsip";
          repo = "sidekick.nvim";
          rev = "8350ac42bff9fe9afdcd0438534010ac97739dd1";
          hash = "sha256-5Kf24P5HTRicO2+azq+iJnpaJc0Et6JBAj403MtYg2k=";
        };
      });
      lazyLoad.settings = {
        cmd = [ "Sidekick" ];
        keys = [
          {
            __unkeyed-1 = "<leader>aa";
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').toggle({ filter = { installed = true } }) end
            '';
            desc = "Sidekick toggle CLI";
          }
          {
            __unkeyed-1 = "<leader>ag";
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').toggle({ name = 'antigravity', focus = true }) end
            '';
            desc = "Sidekick toggle Antigravity";
          }
          {
            __unkeyed-1 = "<leader>ac";
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end
            '';
            desc = "Sidekick toggle Claude";
          }
          {
            __unkeyed-1 = "<leader>as";
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').select() end
            '';
            desc = "Sidekick select CLI";
          }
          {
            __unkeyed-1 = "<leader>ad";
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').close() end
            '';
            desc = "Sidekick detach CLI session";
          }
          {
            __unkeyed-1 = "<leader>at";
            mode = [
              "n"
              "x"
            ];
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').send({ msg = '{this}' }) end
            '';
            desc = "Sidekick send this";
          }
          {
            __unkeyed-1 = "<leader>af";
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').send({ msg = '{file}' }) end
            '';
            desc = "Sidekick send file";
          }
          {
            __unkeyed-1 = "<leader>av";
            mode = [ "x" ];
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').send({ msg = '{selection}' }) end
            '';
            desc = "Sidekick send visual selection";
          }
          {
            __unkeyed-1 = "<leader>ap";
            mode = [
              "n"
              "x"
            ];
            __unkeyed-2 = helpers.mkRaw ''
              function() require('sidekick.cli').prompt() end
            '';
            desc = "Sidekick select prompt";
          }
        ];
      };
      settings = {
        # NES (Copilot-powered ghost-text edit suggestions) needs
        # copilot-lua/copilot LSP, which this config doesn't set up.
        nes.enabled = false;
        # `tools` lives under `cli`, not at the top level -- sidekick's own
        # `Config.tools()` is a *function* that shadows a stray top-level
        # `tools` data key, so a misplaced override there is silently inert
        # (no error, just never applied).
        # Both tools' base `is_proc` (`\<claude\>` / `\<agy\>`) is used by
        # sidekick's tmux mux backend to scan the host process tree for an
        # already-running instance to reattach to (zellij's backend instead
        # reattaches by a deterministic session name, so is_proc is moot
        # there) - but `claude`/`agy` actually run inside an agentspace
        # microVM's own kernel, invisible to the host `ps` tree entirely.
        # What the host tree *does* show (see a live `ps` of the qemu/ssh
        # processes) is the guest launch script's store path, named
        # `agentspace-<name>` (../../vms/agentspace/lib.nix's `guestLaunch`),
        # literally present in the `ssh ... bash -lc
        # /nix/store/...-agentspace-claude` invocation - so match on that
        # instead of the binary name.
        cli.tools.claude = {
          cmd = [ "claude-vm" ];
          is_proc = "agentspace-claude";
        };
        # The PR's tool file is sk/cli/antigravity.lua, so the tool's
        # registered name is "antigravity" (its own `cmd` is `{ "agy" }`,
        # the actual binary name) - not "agy". Overriding `cli.tools.agy`
        # instead would silently create an unrelated second tool with none
        # of antigravity.lua's `is_proc`/`url`/`format`.
        cli.tools.antigravity = {
          cmd = [ "agy-vm" ];
          is_proc = "agentspace-agy";
        };
      };
    };
  };
}
