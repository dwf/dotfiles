{ pkgs, ... }:
{
  imports = [
    ../.
    ../../../overlays/pianoteq.nix
  ];

  home.packages = [ pkgs.pianoteq.stage-8 ];
}
