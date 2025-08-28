{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [ inputs.niri.homeModules.niri ];
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
  ];
  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
    settings = {
      binds = with config.lib.niri.actions; {
        "Mod+Return".action = spawn "alacritty";
      };
    };
  };
}
