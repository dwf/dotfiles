{ config, lib, pkgs, ... }:

let
  screenBacklight = "sysfs/backlight/intel_backlight";
  keyboardBacklight = "sysfs/leds/smc::kbd_backlight";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
in
{
  imports = [
    ../.
    ../profiles/hidpi.nix
  ];

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
    packages = with pkgs; [
      bintools
      cdrtools
      ddrescue
      gimp
      home-assistant-cli
      lame
      mplayer
      nmap
      screen
      scrot
      visidata
      wakeonlan
    ];
  };
}
