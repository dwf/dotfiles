{ lib, pkgs, ... }:

let
  keyboardBacklight = "sysfs/leds/smc::kbd_backlight";
in
{
  imports = [
    ../.
    ../profiles/x11/laptop.nix
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-medium; };
  };

  services.picom.vSync = true;

  xsession = {
    windowManager.i3.config = {
      keybindings = lib.mkOptionDefault {
        # MacBookPro11,1 media keys care of xev
        XF86LaunchA = "exec rofi -show window";
        "Shift+XF86LaunchA" = "exec rofi -show windowcd";
        XF86KbdBrightnessUp = "exec light -s ${keyboardBacklight} -A 5";
        XF86KbdBrightnessDown = "exec light -s ${keyboardBacklight} -U 5";
        # XF86LaunchB = "";
        # XF86AudioPrev = "";
        # XF86AudioPlay = "";
        # XF86AudioNext = "";
        # XF86AudioPrev = "";
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
