{ pkgs, ... }:
{
  imports = [
    ./cmp.nix
    ./conform.nix
    ./lsp.nix
    ./lsp-lines.nix
    ./luasnip.nix
    ./telescope.nix
    ./treesitter.nix
    ./trouble.nix
  ];

  config = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "treesitter-helpers";
        src = ../treesitter;
        version = "2024-09-05";
      })
    ];

    plugins = {
      dressing.enable = true;
      lualine.enable = true;
      lspkind.enable = true;
      lsp-lines.enable = true;
      nix.enable = true;
      project-nvim.enable = true;
      treesitter-textobjects = {
        enable = true;
        move.enable = true;
        select = {
          enable = true;
        };
      };
      trim.enable = true;
      indent-blankline = {
        enable = true;
        settings.scope = {
          enabled = true;
          show_start = false;
          show_end = false;
        };
      };
      neogen = {
        enable = true;
        keymaps.generate = "<Leader>ga";
      };
      gitblame = {
        enable = true;
        delay = 5000;
      };
      gitsigns.enable = true;
      which-key.enable = true;
      git-conflict.enable = true;
      twilight.enable = true;
      notify.enable = true;
      none-ls = {
        enable = true;
        sources = {
          code_actions.statix.enable = true;
          diagnostics.statix.enable = true;
        };
      };
    };
  };
}
