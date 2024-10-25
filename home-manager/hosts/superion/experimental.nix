{
  imports = [ ./starship ];
  programs = {
    zsh.enable = true;
    fish.enable = true;
    starship = {
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
