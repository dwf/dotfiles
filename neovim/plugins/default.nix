{ pkgs, ... }:
{
  imports = [
    ./cmp.nix
    ./conform.nix
    ./lazydev.nix
    ./lsp.nix
    ./lsp-lines.nix
    ./luasnip.nix
    ./neogen.nix
    ./none-ls.nix
    ./overseer.nix
    ./telescope.nix
    ./treesitter.nix
    ./treesitter-textobjects.nix
    ./trim.nix
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
      indent-blankline = {
        enable = true;
        settings.scope = {
          enabled = true;
          show_start = false;
          show_end = false;
        };
      };
      gitblame = {
        enable = true;
        settings.delay = 5000;
      };
      gitsigns.enable = true;
      which-key.enable = true;
      git-conflict.enable = true;
      twilight.enable = true;
      notify.enable = true;
      tmux-navigator.enable = true;
      web-devicons.enable = true;
    };
  };
}
