# Configuration tweaks for boot media for my Beelink EQ12 mini-PC.
# Specifically, get the Wi-Fi working by running with a more recent kernel
# than the 23.11 default.
{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  boot = lib.mkIf (pkgs.linuxPackages.kernelOlder "6.4") {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };
}
