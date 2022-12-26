{ pkgs, ...}:
let
  argonone-utils = pkgs.buildGoModule rec {
    name = "argonone-utils";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "mgdm";
      repo = "argonone-utils";
      rev = "v${version}";
      sha256 = "040319yrdsbkjwqvgq2pgsq0hxm42ps9nbv8s0vcwxc7v7l9la6d";
    };
    vendorSha256 = "18qwmg249lr7xb9f7lrrflhsr7drx750ndqd8hirq5hgj4c4f66k";
  };
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  networking = {
    hostName = "shockwave";
    interfaces.eth0.useDHCP = true;
  };

  boot = {
    # For building images for Raspberry Pi Zero W.
    binfmt.emulatedSystems = [ "armv6l-linux" ];

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

  hardware.i2c.enable = true;
  hardware.raspberry-pi."4".i2c1.enable = true;

  systemd.services.argonone-fancontrold = {
    enable = true;
    wantedBy = [ "default.target" ];
    serviceConfig = {
      DynamicUser = true;
      Group = "i2c";
      ExecStart = "${argonone-utils}/bin/argonone-fancontrold";
    };
  };

  services.printing = {
    enable = true;
    drivers = [ pkgs.brlaser ];
  };

  system.stateVersion = "21.11";
}
