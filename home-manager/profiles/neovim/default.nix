{ pkgs, ... }:
{
  imports = [ ../../modules/nvim-lsp.nix ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;

    package = pkgs.neovim-unwrapped.overrideAttrs (_: rec {
      version = "0.6.1";
      src = pkgs.fetchFromGitHub {
        owner = "neovim";
        repo = "neovim";
        rev = "v${version}";
        sha256 = "sha256-0XCW047WopPr3pRTy9rF3Ff6MvNRHT4FletzOERD41A=";
      };
    });

    plugins = with pkgs.vimPlugins; [
      vim-nix
      ctrlp
      (
        nvim-lspconfig.overrideAttrs (old: {
          version = "2022-02-06";
          src = pkgs.fetchFromGitHub {
            owner = "neovim";
            repo = "nvim-lspconfig";
            rev = "2008c5cebf2b84c5e5f8a566480b022ab2e7ebab";
            sha256 = "0698i51s6dgcanw1iz9zhb8hk6ls2zrvas4i8sqpw7jwr9vnygah";
          };
        })
      )
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
          ".update_capabilities(capabilities)";
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