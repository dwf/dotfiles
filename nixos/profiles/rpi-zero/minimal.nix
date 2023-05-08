{ lib, pkgs, ... }: {
  # This module is imported by sd-image-raspberrypi.nix and pulls in
  # a lot of stuff that's unnecessary for a truly minimal install
  # (like vim).
  disabledModules = [ "profiles/base.nix" ];

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  hardware.enableRedistributableFirmware = lib.mkForce false;

  nixpkgs.overlays = [
    # Work around https://github.com/NixOS/nixpkgs/issues/154163
    (self: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // {
        allowMissing = true;
      });
    })
  ];

  # By default, auto-login as root for the physical (and serial) consoles.
  services.getty.autologinUser = lib.mkDefault "root";
}
