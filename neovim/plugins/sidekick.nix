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

    keymaps = [
      {
        key = "<leader>aa";
        action = helpers.mkRaw ''
          function() require('sidekick.cli').toggle() end
        '';
        options.desc = "Sidekick toggle CLI";
      }
      {
        key = "<leader>ag";
        action = helpers.mkRaw ''
          function() require('sidekick.cli').toggle({ name = 'antigravity', focus = true }) end
        '';
        options.desc = "Sidekick toggle Antigravity";
      }
      {
        key = "<leader>ac";
        action = helpers.mkRaw ''
          function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end
        '';
        options.desc = "Sidekick toggle Claude";
      }
      {
        key = "<leader>as";
        action = helpers.mkRaw ''
          function() require('sidekick.cli').select() end
        '';
        options.desc = "Sidekick select CLI";
      }
      {
        key = "<leader>ad";
        action = helpers.mkRaw ''
          function() require('sidekick.cli').close() end
        '';
        options.desc = "Sidekick detach CLI session";
      }
      {
        key = "<leader>at";
        mode = [
          "n"
          "x"
        ];
        action = helpers.mkRaw ''
          function() require('sidekick.cli').send({ msg = '{this}' }) end
        '';
        options.desc = "Sidekick send this";
      }
      {
        key = "<leader>af";
        action = helpers.mkRaw ''
          function() require('sidekick.cli').send({ msg = '{file}' }) end
        '';
        options.desc = "Sidekick send file";
      }
      {
        key = "<leader>av";
        mode = [ "x" ];
        action = helpers.mkRaw ''
          function() require('sidekick.cli').send({ msg = '{selection}' }) end
        '';
        options.desc = "Sidekick send visual selection";
      }
      {
        key = "<leader>ap";
        mode = [
          "n"
          "x"
        ];
        action = helpers.mkRaw ''
          function() require('sidekick.cli').prompt() end
        '';
        options.desc = "Sidekick select prompt";
      }
    ];
  };
}
