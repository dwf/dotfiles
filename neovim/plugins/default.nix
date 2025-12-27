{ lib, ... }:
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
    # ./treesitter-textobjects.nix
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
        git-conflict.enable = true;
        lspkind.enable = true;
        nix.enable = true;
        project-nvim = {
          enable = true;
          lazyLoad.settings.event = DeferredUIEnter;
          # package = pkgs.vimPlugins.project-nvim.overrideAttrs (_: {
          #   patches = [
          #     (builtins.fetchurl {
          #       url = "https://github.com/ahmedkhalf/project.nvim/pull/183/commits/715491d807e12da417c788bbd6735d4b68268f14.patch";
          #       sha256 = "sha256:1067sd47sixix2r5a9zg7xzqgrzkb72aqkc9flc1g3q0akynrpii";
          #     })
          #   ];
          # });
        };
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
