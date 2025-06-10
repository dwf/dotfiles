{ pkgs, lib, ... }:
{
  imports = [
    ./cmp.nix
    ./conform.nix
    ./hardtime.nix
    ./lazydev.nix
    ./lsp.nix
    ./lsp-lines.nix
    ./lualine.nix
    ./luasnip.nix
    ./neogen.nix
    ./none-ls.nix
    ./overseer.nix
    ./snacks.nix
    ./treesitter.nix
    ./treesitter-textobjects.nix
    ./trim.nix
    ./trouble.nix
  ];

  config =
    let
      DeferredUIEnter = "DeferredUIEnter";
    in
    {
      extraPlugins = [
        (pkgs.vimUtils.buildVimPlugin {
          pname = "treesitter-helpers";
          src = ../treesitter;
          version = "2024-09-05";
          nvimSkipModules = [ "treesitter-helpers.python" ];
        })
      ];

      plugins =
        {
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
          git-conflict.enable = true;
          lspkind.enable = true;
          nix.enable = true;
          tmux-navigator.enable = true;
        }
        // (lib.genAttrs
          [
            "gitsigns"
            "project-nvim"
            "twilight"
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
