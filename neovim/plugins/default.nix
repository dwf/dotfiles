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
      trim = {
        enable = true;
        package = pkgs.vimUtils.buildVimPlugin {
          pname = "trim.nvim";
          src = pkgs.fetchFromGitHub {
            owner = "cappyzawa";
            repo = "trim.nvim";
            rev = "84a1016c7484943e9fbb961f807c3745342b2462";
            sha256 = "sha256-RzLttgP3eNQK8iQ86/7SwvB/GF8LCNlBhvZevOXMhSM=";
          };
          version = "2024-11-21";
        };
        settings = {
          ft_blocklist = [
            "diff"
            "hgcommit"
            "gitcommit"
          ];
          highlight = true;
        };
      };
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
        delay = 5000;
      };
      gitsigns.enable = true;
      which-key.enable = true;
      git-conflict.enable = true;
      twilight.enable = true;
      notify.enable = true;
    };
  };
}
