{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.niri-flake.homeModules.niri
    ./binds.nix
    ./window-rules.nix
  ];
  nixpkgs.overlays = [
    inputs.niri-flake.overlays.niri
  ];

  home.packages = with pkgs; [
    i3bar-river
    xwayland-satellite
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;
    settings = {
      layout = {
        gaps = 0;
        focus-ring.enable = false;
      };
      outputs."eDP-1".scale = 2.0;
      prefer-no-csd = true;
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            options = "compose:ralt";
          };

          repeat-delay = 300; # ms before repeat starts
          repeat-rate = 50; # characters per second
        };
        touchpad = {
          tap = false;
          natural-scroll = false;
          scroll-method = "two-finger";
          click-method = "clickfinger";
          tap-button-map = "left-right-middle";
          middle-emulation = true;
          disabled-on-external-mouse = false;
        };
      };
      spawn-at-startup = [
        {
          command = [
            "i3bar-river"
            "-c"
            "${config.xdg.configHome}/i3bar-river/config.toml"
          ];
        }
      ];
    };
  };
  xdg.configFile."i3bar-river/config.toml".text = # toml
    ''
      font = "DejaVuSansM Nerd Font:style=Regular"
      height = 16
      command = "i3status-rs ${config.xdg.configHome}/i3status-rust/config-bottom.toml"
      position = "bottom"
    '';
}
