{ lockCmd
, menu ? "rofi -show drun"
, modifier ? "Mod4"  # "Command" key on Mac, right pinky on Ergodox EZ
, terminal ? "alacritty"
, addBars ? true
, functionKeys ? true
, sway ? false
, ...
}:
{ config, lib, pkgs, ... }:
let
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  toggle-intl = pkgs.writeShellScript "toggle-intl.sh" ''
    CURRENT_LAYOUT=$(swaymsg -t get_inputs | ${pkgs.jq}/bin/jq -r '.[] | select(.vendor==1) | .xkb_active_layout_name')

    if [[ "$CURRENT_LAYOUT" == *"intl"* ]]; then
        swaymsg 'input type:keyboard xkb_layout us'
        swaymsg 'input type:keyboard xkb_variant ""'
        swaymsg 'input type:keyboard xkb_options compose:ralt'
        notify-send "⌨️ Keyboard" "US layout (dead keys disabled)"
    else
        swaymsg 'input type:keyboard xkb_layout us'
        swaymsg 'input type:keyboard xkb_variant intl'
        swaymsg 'input type:keyboard xkb_options compose:ralt'
        notify-send "⌨️ Keyboard" "US International (dead keys enabled)"
    fi
  '';
  i3-sway = {
    config = {
      inherit menu modifier terminal;
      keybindings = lib.mkOptionDefault ({
        "${modifier}+l" = lib.mkDefault "exec ${lockCmd}";
        "Shift+${modifier}+d" = "exec rofi -show run";
        "Ctrl+${modifier}+e" = "exec rofi -show emoji";
      } // lib.optionalAttrs functionKeys ({
        "Shift+XF86MonBrightnessUp" = "exec light -A 1";
        "Shift+XF86MonBrightnessDown" = "exec light -U 1";
      } // (if sway then {
        XF86MonBrightnessUp = "exec swayosd-client --brightness raise";
        XF86MonBrightnessDown = "exec swayosd-client --brightness lower";
        XF86AudioMute = "exec swayosd-client --output-volume mute-toggle";
        XF86AudioLowerVolume = "exec swayosd-client --output-volume lower";
        XF86AudioRaiseVolume = "exec swayosd-client --output-volume raise";
        "${modifier}+F12" = "exec ${toggle-intl}";
      } else {
        XF86MonBrightnessUp = "exec light -A 5";
        XF86MonBrightnessDown = "exec light -U 5";
        XF86AudioMute = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
        XF86AudioLowerVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
        XF86AudioRaiseVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
      })));
    } // lib.optionalAttrs sway {
      input = {
        "type:touchpad" = {
          tap_button_map = "lrm";
          click_method = "clickfinger";
          middle_emulation = "enabled";
        };
        "type:keyboard".xkb_options = "compose:ralt";
      };
    } // lib.optionalAttrs addBars {
      bars = [
        { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
      ];
    };
    extraConfig = ''
      for_window [class="^steam$"] floating enable
      for_window [class="^Steam$"] floating enable
      for_window [class="^steam$" title="^Steam$"] floating disable
      '';
  };
in if sway then {
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    inherit (i3-sway) config extraConfig;
  };
} else {
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      inherit (i3-sway) config extraConfig;
    };
  };
}
