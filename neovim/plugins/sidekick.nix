# AI coding CLIs from the editor. `claude` is pointed at the `claude-vm`
# wrapper (see vms/agentspace/claude/wrappers.nix) instead of a bare `claude`
# binary, so `<leader>ac` launches Claude Code sandboxed in the agentspace
# microVM rather than running unsandboxed on the host (`<leader>aa` toggles
# whichever tool is already attached, or opens a picker if none is).
{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    # sidekick.nvim ships a root-level `sk/cli/*.lua` directory (per-tool CLI
    # defaults, e.g. `cmd`), not under a standard runtime subdir. The combined
    # plugin pack (see ./performance.nix) only links standard dirs, so it
    # drops `sk/` -- every tool's `base[name]` lookup then comes back empty,
    # leaving `cmd` nil and crashing `sidekick.cli`. Keep it out of the pack.
    # Upstream: https://github.com/nix-community/nixvim/issues/4482
    performance.combinePlugins.standalonePlugins = [ "sidekick.nvim" ];

    plugins.sidekick = {
      enable = true;
      settings = {
        # NES (Copilot-powered ghost-text edit suggestions) needs
        # copilot-lua/copilot LSP, which this config doesn't set up.
        nes.enabled = false;
        # `tools` lives under `cli`, not at the top level -- sidekick's own
        # `Config.tools()` is a *function* that shadows a stray top-level
        # `tools` data key, so a misplaced override there is silently inert
        # (no error, just never applied).
        cli.tools.claude.cmd = [ "claude-vm" ];
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
