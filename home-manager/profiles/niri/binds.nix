{ config, lib, ... }:
{
  programs.niri.settings.binds =
    with config.lib.niri.actions;
    let
      s = lib.splitString " ";
    in
    {
      # App spawning
      "Mod+Return".action.spawn = "alacritty";
      "Mod+d".action.spawn = s "rofi -show drun";
      "Mod+Shift+d".action.spawn = s "rofi -show run";

      # Media keys
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

      # Focus management
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

      # Window size management
      "Mod+F".action = maximize-column;
      "Mod+R".action = switch-preset-column-width;

      # Workspace management
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;
      "Mod+0".action = focus-workspace 10;

      # Move window to workspace
      "Mod+Ctrl+1".action.move-column-to-workspace = [ 1 ];
      "Mod+Ctrl+2".action.move-column-to-workspace = [ 2 ];
      "Mod+Ctrl+3".action.move-column-to-workspace = [ 3 ];
      "Mod+Ctrl+4".action.move-column-to-workspace = [ 4 ];
      "Mod+Ctrl+5".action.move-column-to-workspace = [ 5 ];
      "Mod+Ctrl+6".action.move-column-to-workspace = [ 6 ];
      "Mod+Ctrl+7".action.move-column-to-workspace = [ 7 ];
      "Mod+Ctrl+8".action.move-column-to-workspace = [ 8 ];
      "Mod+Ctrl+9".action.move-column-to-workspace = [ 9 ];
      "Mod+Ctrl+0".action.move-column-to-workspace = [ 10 ];
    };
}
