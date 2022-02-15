{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      ctrlp
    ];
    extraConfig = builtins.readFile ./basic.vim;
  };
}
