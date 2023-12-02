{ config, lib, pkgs, ... }: {
  networking = {
    # Do not also set an interface's useDHCP = true unless you want them to get
    # into a fight.
    networkmanager.enable = true;

    # Implicitly trust connections over tailscale.
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  # Backlight control from the command line.
  programs.light.enable = true;

  # Save and restore backlight on suspend/resume.
  powerManagement = {
    powerDownCommands = "${pkgs.light}/bin/light -O";
    powerUpCommands = "${pkgs.light}/bin/light -I";
  };

  # OpenSSH is enabled by default in global.nix. Keep it enabled, but don't
  # drop the firewall for it (only tailscale, and no passwords).
  services.openssh = {
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Disable tap-to-click and use multi-touch clicks on touchpad if using X11.
  services.xserver.libinput = lib.mkIf config.services.xserver.enable {
    enable = true;
    touchpad = {
      tapping = false;
      clickMethod = "clickfinger";
    };
  };
}
