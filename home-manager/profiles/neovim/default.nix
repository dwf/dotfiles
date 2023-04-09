{ config, lib, pkgs, ... }:
{
  imports = [
    ../../modules/nvim-lsp.nix
    ../../modules/nvim-cmp.nix
    ./snippets
  ];

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
    pluginConfig.nvim-cmp = {
      enable = true;
      sources = [
        { name = "nvim_lsp"; }
        { name = "path"; }
        { name = "vsnip"; }
        { name = "buffer"; keywordLength = 5; }
      ];
      preselectItem = false;
      snippetExpand = ''
        function(args)
          vim.fn["vsnip#anonymous"](args.body)
        end
      '';
      experimental = {
        nativeMenu = false;
        ghostText = true;
      };
    };
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./basic.vim)
    ];
  };
}
