{ pkgs, ...}:
{
  home.packages = with pkgs; [
    noto-fonts
    nerdfonts
    emojione
  ];

  programs.alacritty = {
    enable = true;
    settings.font.size = 9;
    settings.background_opacity = 0.5;
    settings.env.TERM = "xterm-256color";
  };

  # Enabling via programs.google-chrome currently broken.
  # https://github.com/nix-community/home-manager/issues/1383#issuecomment-873393000
  programs.chromium = {
    enable = true;
    package = pkgs.google-chrome.override {
      # TODO(dwf): This should be done by writing out chrome-flags.conf.
      commandLineArgs = "--enable-gpu-rasterization --enable-features=VaapiVideoDecoder";
    };
  };

  programs.feh.enable = true;
}
