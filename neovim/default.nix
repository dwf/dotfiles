{ helpers, pkgs, ... }:
{
  imports = [
    ./completion.nix
    ./diagnostics.nix
    ./formatting.nix
    ./llm.nix
    ./lsp.nix
    ./keymaps
  ];
  config = {
    package = pkgs.neovim-unwrapped.overrideAttrs rec {
      version = "0.10.1";
      src = pkgs.fetchFromGitHub {
        owner = "neovim";
        repo = "neovim";
        rev = "v${version}";
        hash = "sha256-OsHIacgorYnB/dPbzl1b6rYUzQdhTtsJYLsFLJxregk=";
      };
    };
    vimAlias = true;
    colorschemes.tokyonight.enable = true;
    plugins = {
      comment.enable = true;
      lualine.enable = true;
      lspkind.enable = true;
      lsp-lines.enable = true;
      nix.enable = true;
      project-nvim.enable = true;
      telescope = {
        enable = true;
        keymaps = {
          "<C-p>" = {
            action = "find_files";
            options = {
              silent = true;
              desc = "Telescope: find files";
            };
          };
        };
        settings.defaults.mappings = {
          i."<Esc>" = helpers.mkRaw "require('telescope.actions').close";
        };
      };
      treesitter.enable = true;
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
      luasnip = {
        enable = true;
        extraConfig.enable_autosnippets = true;
        fromLua = [ { paths = ./snippets; } ];
      };
    };

    opts = {
      confirm = true;
      cursorline = true;
      ignorecase = true;
      smartcase = true;
      incsearch = true;
      laststatus = 2;
      ruler = true;
      showmatch = true;
      wildmode = "list:longest";
      autoindent = true;
      backspace = "indent,eol,start";
      smartindent = true;
      smarttab = true;
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      expandtab = true;
    };

    highlight = {
      CursorLine = {
        ctermbg = "black";
        cterm.bold = true;
      };
      Pmenu = {
        ctermbg = "black";
        ctermfg = "white";
      };
    };

    globals.fromcwd_snippet_prefix = "/home/dwf/src";
  };
}
