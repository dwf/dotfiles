{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking.hostName = "skyquake";

  # Do not also set an interface's useDHCP = true unless you want them to get
  # into a fight.
  networking.networkmanager.enable = true;

  # The hardware scan enabled the correct WiFi module. Prohibit the impostors.
  boot.blacklistedKernelModules = [ "b43" "bcma" ];

  # Spin up the CPU frequency less quickly, sparing the battery.
  powerManagement.cpuFreqGovernor = "conservative";

  # Overrides the default of true in global.nix.
  services.sshd.enable = false;

  # The hardware scan was smart enough to add the swap device but not smart
  # enough to add the LUKS mapper for it.
  boot.initrd.luks.devices.cryptswap.device = "/dev/sda2";

  # Backlight control from the command line.
  programs.light.enable = true;

  services.xserver = {
    libinput = {
      enable = true;
      touchpad.tapping = false;
    };
    displayManager.lightdm.greeters.gtk = {
      # Fix for tiny cursor on HiDPI display in the display manager.
      # There's a separate fix in home config for once we're logged in.
      cursorTheme.size = 32;
      extraConfig = "xft-dpi = 192";
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
