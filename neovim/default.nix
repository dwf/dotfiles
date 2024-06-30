{ pkgs, ... }:
{
  imports = [
    ./completion.nix
    ./diagnostics.nix
    ./formatting.nix
  ];
  config = {
    vimAlias = true;
    colorschemes.tokyonight.enable = true;
    plugins = {
      comment.enable = true;
      lualine.enable = true;
      lspkind.enable = true;
      lsp-lines.enable = true;
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          pyright.enable = true;
          nil-ls.enable = true;
        };
      };
      nix.enable = true;
      project-nvim.enable = true;
      telescope.enable = true;
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
    keymaps = [
      {
        action = "<cmd>Telescope fd<CR>";
        key = "<C-p>";
        options = {
          silent = true;
          desc = "Telescope: find files";
        };
      }
    ];
  };
}
