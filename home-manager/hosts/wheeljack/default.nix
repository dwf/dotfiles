{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/wayland
    ../../../overlays/pianoteq.nix
  ];

  home.packages = [ pkgs.pianoteq.stage-8 ];
}
