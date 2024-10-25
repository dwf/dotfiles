{
  programs = {
    zsh.enable = true;
    fish.enable = true;
    starship = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
