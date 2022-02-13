# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/87af0fc1-72f2-4b7a-8ef6-38370340a32d";
      fsType = "btrfs";
      options = [ "subvol=@rootnix" ];
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/644f759a-1e53-4b34-ad16-8cb168cb1d33";

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/87af0fc1-72f2-4b7a-8ef6-38370340a32d";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/1D1D-F62C";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/975f6e11-8697-4032-8245-c855929777d1"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # high-resolution display
  hardware.video.hidpi.enable = lib.mkDefault true;
}