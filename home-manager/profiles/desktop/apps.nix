{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    emojione
    libnotify
    # N.B. nix-community/home-manager#6160
    noto-fonts
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.fantasque-sans-mono
    nerd-fonts.jetbrains-mono
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      font.normal = {
        family = "DejaVuSansM Nerd Font";
        style = "Regular";
      };
      font.size = 9;
      window.opacity = 0.5;
      env.TERM = "xterm-256color";
    };
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
