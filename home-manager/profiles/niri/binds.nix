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

      # Move windows
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+L".action = move-column-right;

      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+Right".action = move-column-right;

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

      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+Page_Down".action = focus-workspace-down;

      # Move window to workspace
      "Mod+Shift+1".action.move-column-to-workspace = [ 1 ];
      "Mod+Shift+2".action.move-column-to-workspace = [ 2 ];
      "Mod+Shift+3".action.move-column-to-workspace = [ 3 ];
      "Mod+Shift+4".action.move-column-to-workspace = [ 4 ];
      "Mod+Shift+5".action.move-column-to-workspace = [ 5 ];
      "Mod+Shift+6".action.move-column-to-workspace = [ 6 ];
      "Mod+Shift+7".action.move-column-to-workspace = [ 7 ];
      "Mod+Shift+8".action.move-column-to-workspace = [ 8 ];
      "Mod+Shift+9".action.move-column-to-workspace = [ 9 ];
      "Mod+Shift+0".action.move-column-to-workspace = [ 10 ];

      # Consume window from right into current column (stack vertically)
      "Mod+Comma".action = consume-window-into-column;

      # Expel focused window from column (make it its own column)
      "Mod+Period".action = expel-window-from-column;

      # Quit niri
      "Mod+Control+Backspace".action = quit;
    };
}
