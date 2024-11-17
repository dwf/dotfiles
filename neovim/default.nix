{ pkgs, ... }:
{
  imports = [
    ./keymaps
    ./plugins
  ];
  config = {
    package = pkgs.neovim-unwrapped.overrideAttrs rec {
      version = "0.10.2";
      src = pkgs.fetchFromGitHub {
        owner = "neovim";
        repo = "neovim";
        rev = "v${version}";
        hash = "sha256-+qjjelYMB3MyjaESfCaGoeBURUzSVh/50uxUqStxIfY=";
      };
    };
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
