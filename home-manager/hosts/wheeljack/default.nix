{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/wayland.nix
    ../../profiles/niri
  ];
}
