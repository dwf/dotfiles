{ lib, pkgs, ... }:
{
  imports = [
    ./awk-ward.nix
    ./bazel-helpers.nix
    ./blink-edit.nix
    ./completion.nix
    ./conform.nix
    ./dap.nix
    ./hardtime.nix
    ./lazydev.nix
    ./lsp.nix
    ./lsp-lines.nix
    ./lualine.nix
    ./luasnip.nix
    ./neogen.nix
    ./nix-develop.nix
    ./nix-fetch-hash.nix
    ./nix-module-args.nix
    ./none-ls.nix
    ./nvim-surround.nix
    ./overseer.nix
    ./python-helpers.nix
    ./sidekick.nix
    ./snacks.nix
    ./textobject-hud.nix
    ./treesitter.nix
    ./treesitter-textobjects.nix
    ./treesj.nix
    ./trim.nix
    ./trouble.nix
  ];

  config =
    let
      DeferredUIEnter = "DeferredUIEnter";
    in
    {
      plugins = {
        # Both are pure on-demand diff viewers, invoked only via their own
        # commands - nothing in this config binds keymaps to either, so
        # gate them on those commands instead of loading at startup.
        codediff = {
          enable = true;
          package = pkgs.vimPlugins.codediff-nvim.overrideAttrs (_: {
            src = pkgs.fetchFromGitHub {
              owner = "dwf";
              repo = "codediff.nvim";
              rev = "feat/dir-mode-path-filter";
              sha256 = "sha256-0K8oR2hz3GDfhcWaGkN/ZeoCC3lfuv2nV5XIujG0+zg=";
            };
          });
          lazyLoad.settings.cmd = [
            "CodeDiff"
            "VscodeDiff"
          ];
        };
        diffview = {
          enable = true;
          lazyLoad.settings.cmd = [
            "DiffviewOpen"
            "DiffviewFileHistory"
            "DiffviewClose"
            "DiffviewFocusFiles"
            "DiffviewToggleFiles"
            "DiffviewRefresh"
            "DiffviewLog"
          ];
        };
        indent-blankline = {
          enable = true;
          settings.scope = {
            enabled = true;
            show_start = false;
            show_end = false;
          };
          lazyLoad.settings.event = DeferredUIEnter;
        };
        lz-n.enable = true;
        gitblame = {
          enable = true;
          settings.delay = 5000;
          lazyLoad.settings.event = DeferredUIEnter;
        };
        lsp-signature.enable = true;
        lspkind.enable = true;
        nix.enable = true;
        render-markdown = {
          enable = true;
          lazyLoad.settings.ft = [ "markdown" ];
        };
        # Its own plugin/tmux_navigator.vim defines these keymaps
        # unconditionally when sourced (not through our config), same as
        # nvim-surround - bare (no explicit action) lz.n key triggers load
        # the plugin on first press and replay the key for the real mapping
        # to take over. The tnoremap variants only get defined when $TMUX is
        # set, but registering the triggers unconditionally is harmless.
        tmux-navigator = {
          enable = true;
          lazyLoad.settings.keys = [
            { __unkeyed-1 = "<C-h>"; }
            { __unkeyed-1 = "<C-j>"; }
            { __unkeyed-1 = "<C-k>"; }
            { __unkeyed-1 = "<C-l>"; }
            { __unkeyed-1 = "<C-\\>"; }
            {
              __unkeyed-1 = "<C-h>";
              mode = "t";
            }
            {
              __unkeyed-1 = "<C-j>";
              mode = "t";
            }
            {
              __unkeyed-1 = "<C-k>";
              mode = "t";
            }
            {
              __unkeyed-1 = "<C-l>";
              mode = "t";
            }
          ];
        };
        # Pure on-demand focus mode - nothing else depends on it being
        # loaded early, so gate it on its own commands instead of
        # DeferredUIEnter.
        twilight = {
          enable = true;
          lazyLoad.settings.cmd = [
            "Twilight"
            "TwilightEnable"
            "TwilightDisable"
          ];
        };
        # No plugin/ file - all its commands only get registered once
        # require('zk').setup() runs, and nothing here binds a keymap to it.
        zk = {
          enable = true;
          settings.picker = "snacks_picker";
          lazyLoad.settings.cmd = [
            "ZkIndex"
            "ZkNew"
            "ZkNewFromTitleSelection"
            "ZkNewFromContentSelection"
            "ZkCd"
            "ZkNotes"
            "ZkBuffers"
            "ZkBacklinks"
            "ZkLinks"
            "ZkInsertLink"
            "ZkInsertLinkAtSelection"
            "ZkMatch"
            "ZkTags"
          ];
        };
      }
      // (lib.genAttrs
        [
          "gitsigns"
          "project-nvim"
          "web-devicons"
          "which-key"
        ]
        (_: {
          enable = true;
          lazyLoad.settings.event = DeferredUIEnter;
        })
      );
    };
}
