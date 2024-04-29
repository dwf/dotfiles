{ pkgs, ... }: {
  plugins = {
    nvim-cmp.enable = true;
    cmp-buffer.enable = true;
    cmp-nvim-lsp.enable = true;
    cmp-nvim-lua.enable = true;
    cmp-path.enable = true;
    cmp-vsnip.enable = true;
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
  };
  extraPlugins = builtins.attrValues {
    inherit (pkgs.vimPlugins)
    ctrlp
    nvim-web-devicons
    vim-vsnip;
  };
}
