{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/x11
    ../../../overlays/pianoteq.nix
  ];

  home.packages = [ pkgs.pianoteq.stage-8 ];
}
