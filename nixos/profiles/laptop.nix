{
  config,
  lib,
  pkgs,
  ...
}:
{
  time.timeZone = null;
  services.automatic-timezoned.enable = true;

  networking = {
    # Do not also set an interface's useDHCP = true unless you want them to get
    # into a fight.
    networkmanager.enable = true;

    # Present a consistent-per-SSID Wi-Fi MAC so DHCP reservations survive
    # roaming between access points (the default "preserve" lets the scan
    # randomization leak through, yielding a fresh lease per association).
    # TODO: promote to a global default in global.nix once the MAC-based
    # reservations on the other NetworkManager hosts have been audited.
    networkmanager.wifi.macAddress = "stable-ssid";

    # Implicitly trust connections over tailscale.
    firewall.trustedInterfaces = [ "tailscale0" ];
  };

  # # Backlight control from the command line.
  hardware.acpilight.enable = true;

  # # Save and restore backlight on suspend/resume.
  # powerManagement = {
  #   powerDownCommands = "${pkgs.light}/bin/light -O";
  #   powerUpCommands = "${pkgs.light}/bin/light -I";
  # };

  # OpenSSH is enabled by default in global.nix. Keep it enabled, but don't
  # drop the firewall for it (only tailscale, and no passwords).
  services.openssh = {
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
