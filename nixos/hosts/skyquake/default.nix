{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../profiles/hidpi.nix
      ../../profiles/laptop.nix
    ];

  networking.hostName = "skyquake";

  # The hardware scan enabled the correct WiFi module. Prohibit the impostors.
  boot.blacklistedKernelModules = [ "b43" "bcma" ];

  # Spin up the CPU frequency less quickly, sparing the battery.
  powerManagement.cpuFreqGovernor = "conservative";

  # Run TLP to (hopefully) improve battery life.
  services.tlp.enable = true;

  # The hardware scan was smart enough to add the swap device but not smart
  # enough to add the LUKS mapper for it.
  boot.initrd.luks.devices.cryptswap.device = "/dev/sda2";

  # Make logind ignore power key events so I don't accidentally cause shutdown.
  services.logind.extraConfig = "HandlePowerKey=ignore";

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  hardware.stadiaController.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
