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
      # Pulled in by libical, which is pulled in by bluez.
      # By default, glSupport = true which pulls in a bunch of unnecessary
      # stuff for a headless box, including libglvnd which fails to build.
      cairo = super.cairo.override { glSupport = false; };

      # ghc is unsupported on armv6l-linux.
      nix-tree = super.emptyDirectory;
    })

    # Work around https://github.com/NixOS/nixpkgs/issues/154163
    (self: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // {
        allowMissing = true;
      });
    })

    # We don't need zfs, and zfs-user is at the root of a dependency chain
    # with something broken (ldb, is a dependency of samba, which is a
    # dependency of zfs-user, for some reason)
    (self: super: {
      zfs = super.zfs.overrideAttrs(_: {
        meta.platforms = [];
      });
    })
  ];

  boot.enableContainers = false;
  documentation = {
    enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };
  security.polkit.enable = false;
  services.udisks2.enable = false;
  fonts.fontconfig.enable = false;
  programs.command-not-found.enable = false;

  hardware = {
    bluetooth.enable = true;
    enableRedistributableFirmware = lib.mkForce false;
    firmware = with pkgs; [
      raspberrypiWirelessFirmware
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [ wirelesstools wpa_supplicant ];
  system.stateVersion = "22.11";
}
