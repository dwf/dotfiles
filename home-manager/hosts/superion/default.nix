{ config, lib, pkgs, ... }:

{
  imports = [
    ../.
    ../../profiles/x11/laptop.nix
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;
}
