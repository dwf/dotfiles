{ config, lib, pkgs, ... }:

{
  imports = [
    ../.
    ../../profiles/x11/laptop.nix
  ];

  services.picom.vSync = true;
}
