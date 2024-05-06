{ pkgs, ... }: {
  imports = [
    ./completion.nix
    ./trailing-whitespace.nix
  ];
  config = {
    plugins = {
      lspkind.enable = true;
      nix.enable = true;
      trouble.enable = true;
      lsp = {
        enable = true;
        servers = {
          pyright.enable = true;
          nil_ls.enable = true;
        };
      };
      treesitter.enable = true;
    };

    extraPlugins = builtins.attrValues {
      inherit (pkgs.vimPlugins)
      ctrlp
      nvim-web-devicons
      vim-vsnip;
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
  };
}
