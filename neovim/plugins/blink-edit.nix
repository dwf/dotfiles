# Cursor-style next-edit-suggestion ghost text, backed by a local llama.cpp
# server (see ../../home-manager/hosts/superion/llama-nes.nix) rather than
# Copilot -- unlike sidekick.nvim's NES, unrelated to Saghen's blink.cmp
# despite the name (just checks the completion popup's visibility so <Tab>
# doesn't collide).
#
# No typed nixvim module exists for this plugin upstream (checked nixvim's
# plugins/by-name/), so this defines one itself via the same
# lib.nixvim.plugins.mkNeovimPlugin helper nixvim's own by-name plugins use
# (see plugins/TEMPLATE.nix in the nixvim source) -- gives a real
# plugins.blink-edit.enable/settings, converted to Lua and passed to
# require("blink-edit").setup(...) automatically, same as every other plugin
# in this tree (e.g. ./sidekick.nix), instead of a bespoke option name plus a
# hand-written extraConfigLua string.
{ pkgs, lib, ... }:
let
  helpers = lib.nixvim;
in
{
  imports = [
    (lib.nixvim.plugins.mkNeovimPlugin {
      name = "blink-edit";
      maintainers = [ ];
      package = lib.mkOption {
        type = lib.types.package;
        description = "blink-edit.nvim package.";
        default = pkgs.vimUtils.buildVimPlugin {
          pname = "blink-edit.nvim";
          version = "2026-02-01";
          src = pkgs.fetchFromGitHub {
            owner = "BlinkResearchLabs";
            repo = "blink-edit.nvim";
            rev = "220f5777f5597f6d7868981d6ff9b6218247fec4";
            hash = "sha256-GxO9SlfiOWXAsTtIkAfygISO83BWif3+AktXlHGi0q0=";
          };
          # Upstream's context.lsp definitions/references lookup
          # (core/context_manager.lua, collect_lsp_locations) calls
          # vim.lsp.util.make_position_params() with no encoding, which
          # Neovim 0.11+ warns on every call ("position_encoding param is
          # required..."), firing on every debounced context refresh while
          # typing. Patch to pass the first attached client's
          # offset_encoding explicitly -- the same value Neovim's own
          # fallback picks, just without the warning. Drop once upstream
          # fixes this (BlinkResearchLabs/blink-edit.nvim).
          postPatch = ''
            substituteInPlace lua/blink-edit/core/context_manager.lua \
              --replace-fail \
                'local params = vim.lsp.util.make_position_params()' \
                'local params = vim.lsp.util.make_position_params(0, (get_attached_clients(bufnr)[1] or {}).offset_encoding or "utf-16")'

            # The jump-indicator hint (core/render.lua) advertises
            # cfg.keymaps.insert.accept (<C-y>), not <Tab>, which is what
            # actually accepts via ../../keymaps/default.nix. Can't just set
            # keymaps.insert.accept = "<Tab>" instead -- blink-edit would
            # register its own lazy-loaded <Tab> keymap that clobbers our
            # startup-registered one. Patch the hint text directly instead.
            substituteInPlace lua/blink-edit/core/render.lua \
              --replace-fail \
                'key = cfg.keymaps.insert.accept' \
                'key = "<Tab>"'
          '';
        };
      };
    })
  ];

  # This tree's actual default for it: enabled, pointed at the socket-
  # activated local backend. mkDefault throughout so a derived configuration
  # without a matching llama-nes backend (i.e. anything that isn't superion)
  # can cleanly override with `plugins.blink-edit.enable = false;` instead of
  # hitting a conflicting-definition error.
  config.plugins.blink-edit = {
    enable = lib.mkDefault true;
    settings = lib.mkDefault {
      llm = {
        backend = "openai";
        provider = "sweep";
        url = "http://127.0.0.1:8000";
        model = "sweep";
        temperature = 0.0;
        max_tokens = 512;
        # Backend is socket-activated (see llama-nes.nix) and can be fully
        # stopped after an idle period, so the first request after a break
        # pays real cold-start cost (proxy wake + model load + Vulkan init),
        # not just network round-trip -- longer than the 5s default.
        timeout_ms = 15000;
      };
      keymaps.insert = {
        # Default <Tab> collides with the native-completion popup and
        # luasnip's expand/jump -- <Tab> itself is now bound centrally in
        # ../keymaps/default.nix (blink-edit is priority 3 there, calling
        # accept() directly), so this is just a secondary direct-accept key.
        accept = "<C-y>";
      };
    };

    # lazyLoad.enable defaults to true as soon as lazyLoad.settings has any
    # non-null attribute set (see nixvim's mkLazyLoadOption) -- no separate
    # `enable = true;` needed here, matching ./sidekick.nix.
    lazyLoad.settings = {
      event = "DeferredUIEnter";
      # This tree's plugins.blink-edit config (above) is evaluated on every
      # host, but only superion actually runs a llama-nes backend (see
      # ../../home-manager/hosts/superion/llama-nes.nix). Rather than lean on
      # blink-edit's own connection-refused handling to make that harmless
      # elsewhere, gate the plugin's *load* on the backend actually being
      # configured on this machine: `enabled` is lz.n's own PluginSpec field
      # (passed straight through here since lazyLoad.settings is a freeform
      # mkSettingsOption) -- checked by lz.n itself both when specs are
      # parsed and again immediately before `packadd`, so a false return
      # means require("blink-edit").setup() never runs at all: no
      # autocmds, no per-keystroke engine.trigger(), nothing.
      #
      # ~/.config/systemd/user/<name>.socket is where home-manager's
      # systemd.user.sockets.llama-server-nes-proxy (see llama-nes.nix)
      # lands -- its presence is a cheap, synchronous proxy for "this host
      # has the backend wired up", without spawning `systemctl` at startup.
      enabled = helpers.mkRaw ''
        function()
          local has_backend =
            vim.uv.fs_stat(vim.fn.expand("~/.config/systemd/user/llama-server-nes-proxy.socket")) ~= nil
          -- enabled() runs synchronously during startup's require('lz.n').load(),
          -- before deferred/UI-dependent notify backends (snacks, etc.) are
          -- necessarily ready -- schedule so this always lands as a normal
          -- notification instead of racing plugin setup or a startup echo.
          if not has_backend then
            vim.schedule(function()
              vim.notify(
                "blink-edit: no llama-nes backend socket found, skipping NES setup",
                vim.log.levels.WARN
              )
            end)
          end
          return has_backend
        end
      '';
      # Disable immediately after setup, waiting for manual enable.
      # Temporarily monkeypatch the log function to stop it from issuing
      # a notification.
      after = helpers.mkRaw ''
        function()
          local log = require('blink-edit.log')
          local log_info = log.info
          log.info = function(_) end
          require('blink-edit').disable()
          log.info = log_info
        end
      '';
      keys = [
        {
          __unkeyed-1 = "<leader>ae";
          __unkeyed-2 = helpers.mkRaw ''
            function() require('blink-edit').toggle() end
          '';
          desc = "Toggle next-edit predictions (blink-edit)";
        }
      ];
    };
  };
}
