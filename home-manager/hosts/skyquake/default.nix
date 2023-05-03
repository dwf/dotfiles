{ config, lib, pkgs, ... }:

let
  screenBacklight = "sysfs/backlight/intel_backlight";
  keyboardBacklight = "sysfs/leds/smc::kbd_backlight";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
in
{
  imports = [ ../. ];

  home.sessionVariables = {
    GDK_SCALE = 2;
    GDK_DPI_SCALE = 0.5;
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  programs.i3status-rust.bars.bottom.blocks = lib.mkAfter [
    {
      block = "battery";
      interval = 30;
    }
  ];

  programs.keychain = {
    enable = true;
    enableBashIntegration = true;
    enableXsessionIntegration = true;
    agents = [ "ssh" ];
    keys = [ "id_ed25519" ];
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-medium; };
  };

  services.picom.vSync = true;

  # Suggestions from https://dougie.io/linux/hidpi-retina-i3wm/ for DPI issues
  xresources.properties = {
    "Xft.dpi" = 192;
    "Xft.autohint" = 0;
    "Xft.lcdfilter" = "lcddefault";
    "Xft.hintstyle" = "hintfull";
    "Xft.hinting" = 1;
    "Xft.antialias" = 1;
    "Xft.rgba" = "rgb";
  };

  xsession = {
    windowManager.i3.config = {
      keybindings = lib.mkOptionDefault {
        # MacBookPro11,1 media keys care of xev
        XF86MonBrightnessUp = "exec light -s ${screenBacklight} -A 5";
        "Shift+XF86MonBrightnessUp" = "exec light -s ${screenBacklight} -A 1";
        XF86MonBrightnessDown = "exec light -s ${screenBacklight} -U 5";
        "Shift+XF86MonBrightnessDown" = "exec light -s ${screenBacklight} -U 1";
        XF86LaunchA = "exec rofi -show window";
        "Shift+XF86LaunchA" = "exec rofi -show windowcd";
        # XF86LaunchB = "";
        XF86KbdBrightnessUp = "exec light -s ${keyboardBacklight} -A 5";
        XF86KbdBrightnessDown = "exec light -s ${keyboardBacklight} -U 5";
        # XF86AudioPrev = "";
        # XF86AudioPlay = "";
        # XF86AudioNext = "";
        # XF86AudioPrev = "";
        XF86AudioMute = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
        XF86AudioLowerVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
        XF86AudioRaiseVolume = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
      };
    };
  };

  home = {
    pointerCursor.size = 48;
    packages = with pkgs; [
      captive-browser
      home-assistant-cli
      scrot
    ];
  };
}
