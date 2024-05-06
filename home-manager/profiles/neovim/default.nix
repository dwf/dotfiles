{ pkgs, ... }:
{
  imports = [
    ./snippets
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
  } // (import ../../../neovim/default.nix { inherit pkgs; }).config;
}
