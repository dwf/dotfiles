{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/desktop/laptop.nix
    ../../profiles/wayland.nix
    ./audio.nix
    ./niri.nix
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;

  home.packages = with pkgs; [ calibre ];
}
