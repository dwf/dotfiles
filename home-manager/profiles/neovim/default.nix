{ lib, pkgs, ... }:
{
  # imports = [ ../../modules/nvim-lsp.nix ];

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
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./basic.vim)
      "\n\nlua << EOF"
      ''
      local pyright_binary = '${pkgs.pyright}/bin/pyright-langserver'
      local rnix_binary = '${pkgs.rnix-lsp}/bin/rnix-lsp'
      ''
      (builtins.readFile ./lsp.lua)
      (builtins.readFile ./completion.lua)
      "EOF"
    ];
  };
}
