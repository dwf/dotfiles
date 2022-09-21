{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  networking = {
    hostName = "skyquake";
    # Do not also set an interface's useDHCP = true unless you want them to get
    # into a fight.
    networkmanager.enable = true;

    # Implicitly trust connections over tailscale.
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  # Attempt to fix weird issue where system gets into a state where I get a
  # fully black screen for about a minute after waking from suspend.
  boot.kernelParams = [ "i915.enable_psr=0" ];

  # The hardware scan enabled the correct WiFi module. Prohibit the impostors.
  boot.blacklistedKernelModules = [ "b43" "bcma" ];

  # Spin up the CPU frequency less quickly, sparing the battery.
  powerManagement.cpuFreqGovernor = "conservative";

  # Run TLP to (hopefully) improve battery life.
  services.tlp.enable = true;

  # OpenSSH is enabled by default in global.nix. Keep it enabled, but don't
  # drop the firewall for it (only tailscale, and no passwords).
  services.openssh = {
    openFirewall = false;
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

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

  # Save and restore backlight on suspend/resume.
  powerManagement = {
    powerDownCommands = "${pkgs.light}/bin/light -O";
    powerUpCommands = "${pkgs.light}/bin/light -I";
  };

  # Make logind ignore power key events so I don't accidentally cause shutdown.
  services.logind.extraConfig = "HandlePowerKey=ignore";

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
