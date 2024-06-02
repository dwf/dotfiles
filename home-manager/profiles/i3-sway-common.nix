{ config, lib, pkgs, ...}:
let
  config' = config;
  mod = "Mod4";
  lockCmd = "${pkgs.i3lock}/bin/i3lock -n -c 000000";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
in {
  inherit lockCmd;
  function-keys = {
    XF86MonBrightnessUp = "exec light -A 5";
    "Shift+XF86MonBrightnessUp" = "exec light -A 1";
    XF86MonBrightnessDown = "exec light -U 5";
    "Shift+XF86MonBrightnessDown" = "exec light -U 1";
    XF86AudioMute = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
    XF86AudioLowerVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
    XF86AudioRaiseVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
  };
  config = {
    modifier = mod;   # "Command" key on Mac, right pinky on Ergodox EZ
    window.titlebar = false;
    terminal = lib.mkDefault "alacritty";
    menu = "rofi -show drun";
    keybindings = lib.mkOptionDefault {
      "${mod}+l" = lib.mkDefault "exec ${lockCmd}";
      "Shift+${mod}+d" = "exec rofi -show run";
      "Ctrl+${mod}+e" = "exec rofi -show emoji";
    };
  };
  extraConfig = ''
    for_window [class="^steam$"] floating enable
    for_window [class="^Steam$"] floating enable
    for_window [class="^steam$" title="^Steam$"] floating disable
  '';
  bars = [
    { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config'.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
  ];
}
