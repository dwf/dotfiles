{ pkgs, ... }: {
  imports = [
    ./completion.nix
    ./diagnostics.nix
    ./trailing-whitespace.nix
  ];
  config = {
    vimAlias = true;
    colorschemes.tokyonight.enable = true;
    plugins = {
      lualine.enable = true;
      lspkind.enable = true;
      lsp = {
        enable = true;
        servers = {
          pyright.enable = true;
          nil_ls.enable = true;
        };
      };
      project-nvim.enable = true;
      telescope.enable = true;
      treesitter = {
        enable = true;
        indent = true;
      };
      indent-blankline = {
        enable = true;
        scope = {
          enabled = false;  # TODO: configure
        };
      };
      neogen = {
        enable = true;
        keymaps.generate = "<Leader>ga";
      };
    };

    extraPlugins = with pkgs.vimPlugins; [
      comment-nvim
      nvim-web-devicons
      twilight-nvim
    ];

    extraConfigLuaPost = ''
      require('twilight').setup {}
      require('Comment').setup {}
    '';

    options = {
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
        options.silent = true;
      }
    ];
  };
}
