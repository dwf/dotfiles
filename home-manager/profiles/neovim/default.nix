{ pkgs, ... }:
{
  imports = [ ../../modules/nvim-lsp.nix ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      ctrlp
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      vim-vsnip
    ];
    extraConfig = builtins.concatStringsSep "\n" [
      (builtins.readFile ./basic.vim)
      "\n\nlua << EOF"
      (builtins.readFile ./completion.lua)
      "EOF"
    ];
    lsp = {
      enable = true;
      servers.rnix = {
        enable = true;
        cmd = [ "${pkgs.rnix-lsp}/bin/rnix-lsp" ];
        filetypes = [ "nix" ];
        root_patterns = [ "flake.nix" ];
      };
      onAttach = {
        enableOmniFunc = true;
        defaultKeyMapOptions = {
          noremap = true;
          silent = true;
        };
        capabilities = "require('cmp_nvim_lsp')" +
          ".default_capabilities()";
        keyMappings = {
          gD = { command = "<cmd>lua vim.lsp.buf.declaration()<CR>"; };
          gd = { command = "<cmd>lua vim.lsp.buf.definition()<CR>"; };
          K = { command = "<cmd>lua vim.lsp.buf.hover()<CR>"; };
          gi = { command = "<cmd>lua vim.lsp.buf.implementation()<CR>"; };
          gr = { command = "<cmd>lua vim.lsp.buf.references()<CR>"; };
          "<C-k>" = { command = "<cmd>lua vim.lsp.buf.signature_help()<CR>"; };
          "<space>wa" = { command = "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>"; };
          "<space>wr" = { command = "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>"; };
          "<space>wl" = { command = "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>"; };
          "<space>D" = { command = "<cmd>lua vim.lsp.buf.type_definition()<CR>"; };
          "<space>rn" = { command = "<cmd>lua vim.lsp.buf.rename()<CR>"; };
          "<space>ca" = { command = "<cmd>lua vim.lsp.buf.code_action()<CR>"; };
          "<space>f" = { command = "<cmd>lua vim.lsp.buf.formatting()<CR>"; };
        };
      };
    };
  };
}
