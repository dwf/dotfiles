{ config, lib, pkgs, ... }:

let
  screenBacklight = "sysfs/backlight/intel_backlight";
  keyboardBacklight = "sysfs/leds/smc::kbd_backlight";
in
{
  nixpkgs.config.allowUnfree = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.bash.enable = true;

  # Enabling via programs.google-chrome currently broken.
  # https://github.com/nix-community/home-manager/issues/1383#issuecomment-873393000

  programs.git = {
    enable = true;
    userName = "David Warde-Farley";
    userEmail = builtins.concatStringsSep "@" [
      "dwf"
      (builtins.concatStringsSep "." [ "google" "com" ])
    ];
    aliases = {
      ca = "commit -a";
      co = "checkout";
      st = "status -a";
      ap = "add -p";
      record = "add -p";
    };
    ignores = [ ".*.swp" "tags" ".ropeproject" ".netrwhist" ];
  };

  programs.ssh = {
    enable = true;
    compression = true;
  };

  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome.override {
      # TODO(dwf): This should be done by writing out chrome-flags.conf.
      commandLineArgs = "--enable-gpu-rasterization --enable-features=VaapiVideoDecoder";
    };
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    plugins = with pkgs.vimPlugins; [
      vim-nix
      ctrlp
    ];
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-medium; };
  };

  programs.alacritty = {
    enable = true;
    settings.font.size = 9;
    settings.background_opacity = 0.2;
    settings.env.TERM = "xterm-256color";
  };

  programs.rofi.enable = true;

  programs.keychain = {
    enable = true;
    enableBashIntegration = true;
    enableXsessionIntegration = true;
    agents = [ "ssh" ];
    keys = [ "id_ed25519" ];
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
          # XF86LaunchA = "";
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
    EDITOR = "nvim";
  };
}
