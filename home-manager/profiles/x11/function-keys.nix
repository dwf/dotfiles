{ lib, pkgs, ... }:
let
  pactl = "${pkgs.pulseaudio}/bin/pactl";
in
{
  xsession = {
    windowManager.i3.config = {
      keybindings = lib.mkOptionDefault {
        XF86MonBrightnessUp = "exec light -A 5";
        "Shift+XF86MonBrightnessUp" = "exec light -A 1";
        XF86MonBrightnessDown = "exec light -U 5";
        "Shift+XF86MonBrightnessDown" = "exec light -U 1";
        XF86AudioMute = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
        XF86AudioLowerVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
        XF86AudioRaiseVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
      };
    };
  };
}
