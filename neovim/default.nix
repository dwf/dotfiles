{
  imports = [
    ./keymaps
    ./plugins
    ./performance.nix
  ];

  config = {
    vimAlias = true;
    colorschemes.tokyonight.enable = true;
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
