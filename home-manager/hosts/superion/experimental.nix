{ pkgs, ... }:
{
  imports = [
    ./starship
    ../../profiles/zsh.nix
    ../../profiles/fish.nix
  ];
  programs = {
    starship = {
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
