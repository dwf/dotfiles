{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../.
    ../../profiles/desktop/laptop.nix
    ../../profiles/wayland.nix
    ../../profiles/niri
    ./audio.nix
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;

  nixpkgs.overlays = [
    inputs.niri-flake.overlays.niri
  ];

  home.packages = with pkgs; [ calibre ];
}
