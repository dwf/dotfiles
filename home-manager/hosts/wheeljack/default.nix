{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/wayland.nix
  ];
}
