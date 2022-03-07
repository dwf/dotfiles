{ config, lib, pkgs, ... }:

let
  screenBacklight = "sysfs/backlight/intel_backlight";
  keyboardBacklight = "sysfs/leds/smc::kbd_backlight";
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{
  imports = [ ../. ];

  # Enabling via programs.google-chrome currently broken.
  # https://github.com/nix-community/home-manager/issues/1383#issuecomment-873393000

  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome.override {
      # TODO(dwf): This should be done by writing out chrome-flags.conf.
      commandLineArgs = "--enable-gpu-rasterization --enable-features=VaapiVideoDecoder";
    };
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-medium; };
  };

  programs.alacritty = {
    enable = true;
    settings.font.size = 9;
    settings.background_opacity = 0.5;
    settings.env.TERM = "xterm-256color";
  };

  programs.rofi = {
    enable = true;
    font = "DejaVu Sans Mono 18";
    terminal = "alacritty";
    theme = "Arc-Dark";
    plugins = with pkgs; [ rofi-calc rofi-emoji ];
    extraConfig = {
      modi = lib.concatStringsSep "," [
        "calc"
        "drun"
        "emoji"
        "filebrowser"
        "run"
        "ssh"
      ];
    };
  };

  programs.keychain = {
    enable = true;
    enableBashIntegration = true;
    enableXsessionIntegration = true;
    agents = [ "ssh" ];
    keys = [ "id_ed25519" ];
  };

  programs.i3status-rust = {
    enable = true;
    bars.bottom = {
      settings = {
        theme = "solarized-dark";
        icons_format = " <span font_family='FantasqueSansMono Nerd Font'>{icon}</span> ";
        font = "font pango:DejaVu Sans Mono, Icons 12";
      };
      icons = "material-nf";
      blocks = [
        {
          block = "networkmanager";
        }
        {
          block = "time";
          interval = 60;
          format = "%a %d/%m %R";
        }
        {
          block = "battery";
          interval = 30;
        }
      ];
    };
  };


  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      config = {
        window.titlebar = false;
        terminal = "alacritty";
        menu = "rofi -show run";
        modifier = "Mod4";   # "Command" key.
        keybindings = lib.mkOptionDefault {
          # MacBookPro11,1 media keys care of xev
          XF86MonBrightnessUp = "exec light -s ${screenBacklight} -A 1";
          XF86MonBrightnessDown = "exec light -s ${screenBacklight} -U 1";
          XF86LaunchA = "exec rofi -show window";
          "Shift+XF86LaunchA" = "exec rofi -show windowcd";
          # XF86LaunchB = "";
          XF86KbdBrightnessUp = "exec light -s ${keyboardBacklight} -A 5";
          XF86KbdBrightnessDown = "exec light -s ${keyboardBacklight} -U 5";
          # XF86AudioPrev = "";
          # XF86AudioPlay = "";
          # XF86AudioNext = "";
          # XF86AudioPrev = "";
          # XF86AudioMute = "";
          # XF86AudioLowerVolume = "";
          # XF86AudioRaiseVolume = "";
        };
        bars = [
          { statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.home.homeDirectory}/.config/i3status-rust/config-bottom.toml"; }
        ];
      };
    };
    pointerCursor = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 48;
    };
  };
  services.picom = {
    enable = true;
    backend = "glx";
    vSync = true;
  };

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
  home.sessionVariables = {
    GDK_SCALE = 2;
    GDK_DPI_SCALE = 0.5;
    QT_AUTO_SCREEN_SCALE_FACTOR = 1;
  };

  home.packages = with pkgs; [
    noto-fonts
    nerdfonts
    emojione
  ];
}
