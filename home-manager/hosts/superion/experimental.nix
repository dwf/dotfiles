{
  imports = [
    ./starship
    ../../profiles/zsh.nix
  ];
  programs = {
    fish.enable = true;
    starship = {
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
