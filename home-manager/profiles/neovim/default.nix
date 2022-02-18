{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
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
  };
}
