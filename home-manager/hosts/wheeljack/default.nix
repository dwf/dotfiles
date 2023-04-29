{ pkgs, ... }:
{
  imports = [
    ../.
    ../../../overlays/pianoteq.nix
  ];

  home.packages = [ pkgs.pianoteq.standard-trial ];
}
