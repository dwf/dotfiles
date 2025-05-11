{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/wayland.nix
    ../../../overlays/pianoteq.nix
  ];

  home.packages = [ pkgs.pianoteq.stage_8 ];
}
