{ pkgs, ... }: {
  imports = [
    ./completion.nix
    ./diagnostics.nix
    ./trailing-whitespace.nix
  ];
  config = {
    vimAlias = true;
    plugins = {
      lspkind.enable = true;
      nix.enable = true;
      lsp = {
        enable = true;
        servers = {
          pyright.enable = true;
          nil_ls.enable = true;
        };
      };
      project-nvim.enable = true;
      telescope.enable = true;
      treesitter.enable = true;
    };

    extraPlugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
      nvim-web-devicons;
    };

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
