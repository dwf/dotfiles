{ lib, pkgs, ... }:
{
  imports = [
    ./awk-ward.nix
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
    ./nvim-surround.nix
    ./overseer.nix
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
      #extraPlugins = [
      #  (pkgs.vimUtils.buildVimPlugin {
      #    pname = "treesitter-helpers";
      #    src = ../treesitter;
      #    version = "2024-09-05";
      #    nvimSkipModules = [ "treesitter-helpers.python" ];
      #  })
      #];

      plugins = {
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
        };
        diffview.enable = true;
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
        lspkind.enable = true;
        nix.enable = true;
        render-markdown = {
          enable = true;
          lazyLoad.settings.ft = [ "markdown" ];
        };
        tmux-navigator.enable = true;
        zk = {
          enable = true;
          settings.picker = "snacks_picker";
        };
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
