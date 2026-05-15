{ pkgs, ... }:
{
  imports = [
    ./keymaps
    ./plugins
    ./performance.nix
  ];

  config = {
    diagnostic.settings = {
      float.severity_sort = true;
      signs.text = {
        "__rawKey__vim.diagnostic.severity.ERROR" = "🚨";
        "__rawKey__vim.diagnostic.severity.WARN" = "⚠️";
        "__rawKey__vim.diagnostic.severity.INFO" = "👀";
        "__rawKey__vim.diagnostic.severity.HINT" = "👉";
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
    package = pkgs.neovim-unwrapped.overrideAttrs (_: rec {
      version = "0.12.2";
      src = pkgs.fetchFromGitHub {
        owner = "neovim";
        repo = "neovim";
        rev = "v${version}";
        sha256 = "sha256-V+jZiNv0SvG/GOOUPzmBkOQGrnrN3UW2BY2n9NxP2Eg=";
      };
    });
  };
}
