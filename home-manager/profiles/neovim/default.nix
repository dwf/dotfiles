{ lib, pkgs, ... }:
{
  imports = [ ../../modules/nvim-lsp.nix ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      ctrlp
      nvim-cmp
      cmp-buffer
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-path
      cmp-vsnip
      vim-vsnip
      nvim-lspconfig
      lspkind-nvim
      trouble-nvim
      nvim-web-devicons
    ];
    lsp = {
      enable = true;
      servers = {
        pyright = {
          enable = true;
          setup.cmd = [ "${pkgs.pyright}/bin/pyright-langserver" "--stdio" ];
        };
        rnix = {
          enable = true;
          setup.cmd = [ "${pkgs.rnix-lsp}/bin/rnix-lsp" ];
        };
      };
    };
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./basic.vim)
    ];
  };
}
