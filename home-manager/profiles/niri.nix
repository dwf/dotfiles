{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.niri-flake.homeModules.niri
  ];
  nixpkgs.overlays = [
    inputs.niri-flake.overlays.niri
  ];

  home.packages = with pkgs; [ i3bar-river ];

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
      window-rules = [
        {
          matches = [ ]; # Empty matches = all windows
          draw-border-with-background = false;
        }
      ];
      binds =
        with config.lib.niri.actions;
        let
          s = lib.splitString " ";
        in
        {
          "Mod+Return".action.spawn = "alacritty";
          "Mod+d".action.spawn = s "rofi -show drun";
          "Mod+Shift+d".action.spawn = s "rofi -show run";
          XF86MonBrightnessUp = {
            allow-when-locked = true;
            action.spawn = s "swayosd-client --brightness raise";
          };
          XF86MonBrightnessDown = {
            allow-when-locked = true;
            action.spawn = s "swayosd-client --brightness lower";
          };
          "XF86AudioRaiseVolume" = {
            allow-when-locked = true;
            action.spawn = s "swayosd-client --output-volume raise";
          };
          "XF86AudioLowerVolume" = {
            allow-when-locked = true;
            action.spawn = s "swayosd-client --output-volume lower";
          };
          "XF86AudioMute" = {
            allow-when-locked = true;
            action.spawn = s "swayosd-client --output-volume mute-toggle";
          };
          "Mod+H".action = focus-column-left;
          "Mod+L".action = focus-column-right;
          "Mod+J".action = focus-window-down;
          "Mod+K".action = focus-window-up;

          "Mod+Left".action = focus-column-left;
          "Mod+Right".action = focus-column-right;
          "Mod+Down".action = focus-window-down;
          "Mod+Up".action = focus-window-up;

          "Mod+Home".action = focus-window-top;
          "Mod+End".action = focus-window-bottom;

          "Mod+F".action = maximize-column;
          "Mod+R".action = switch-preset-column-width;

        };
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            options = "compose:ralt";
          };

          repeat-delay = 300; # ms before repeat starts
          repeat-rate = 50; # characters per second
          # track-layout = "global";  # or "window" for per-window layout memory
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
