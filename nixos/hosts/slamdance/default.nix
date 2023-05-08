{ lib, pkgs, ... }:
{
  networking = {
    hostName = "slamdance";
    interfaces.wlan0.useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      # ghc is unsupported on armv6l-linux.
      nix-tree = super.emptyDirectory;
    })
  ];

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "22.11";
}
