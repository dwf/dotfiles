{ pkgs, ... }:
{
  imports = [
    ./keymaps
    ./plugins
    ./ftplugin
    ./performance.nix
  ];

  config = {
    # sidekick-nvim's nixpkgs derivation links in copilot-language-server as a
    # runtimeDep unconditionally, even though NES/Copilot is disabled in our
    # settings (neovim/plugins/sidekick.nix). Stub it out rather than
    # allowing unfree wholesale: nothing calls it with NES off.
    nixpkgs.overlays = [
      (final: prev: {
        copilot-language-server = prev.emptyDirectory;
      })
    ];

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
  };
}
