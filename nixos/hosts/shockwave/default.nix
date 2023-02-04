{ config, pkgs, ...}:
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  networking = {
    hostName = "shockwave";
    networkmanager.enable = true;
  };

  boot = {
    # For building images for Raspberry Pi Zero W.
    binfmt.emulatedSystems = [ "armv6l-linux" ];

    extraModulePackages = with config.boot.kernelPackages; [ rtl88x2bu ];

    # Serial console on GPIO, even though I'm not using it currently.
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
    ];

    loader.generic-extlinux-compatible.enable = false;

    loader.raspberryPi = {
      enable = true;
      version = 4;
    };

    # Load the appropriate driver for the I2C controller.
    initrd.kernelModules = [ "i2c-dev" "i2c-bcm2835" ];
    kernelModules = [ "i2c-dev" "i2c-bcm2835" ];
  };

  environment.systemPackages = with pkgs; [ speedtest-cli wirelesstools ];

  hardware.i2c.enable = true;
  hardware.raspberry-pi."4".i2c1.enable = true;

  services.hardware.argonone.enable = true;

  services.auto-abcde = {
    enable = true;
    outputPath = "/data/music";
    maxEncoderProcesses = 4;
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  system.stateVersion = "21.11";
}
