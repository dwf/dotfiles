{ pkgs, ... }:
{
  # Hardware profile for a MacBookPro11,1.

  # Disable hard-coded ISO layout of the keyboard.
  boot.kernelParams = [
    "hid_apple.iso_layout=0" # Disable hard-coded ISO keyboard layout.
  ];

  hardware.facetimehd.enable = true;
  services.mbpfan.enable = true;

  # Disable ACPI wakeups by XHCI.
  services.udev.extraRules = ''
    SUBSYSTEM=="pci", KERNEL=="0000:00:14.0", ATTR{power/wakeup}="disabled"
  '';

  # Disable LID0 wakeups.
  # See: https://wiki.archlinux.org/title/Mac#Suspend_and_hibernate
  # I was still seeing wakeups immediately after susepnd with just XHCI. This
  # seems to have fixed it, though I have to hit the power button to explicitly
  # wake up. Closing the lid still suspends.
  systemd.services.disable-lid-wake = {
    description = "Disable LID0 wake on boot to prevent spurious wakeups.";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart =
        with pkgs;
        writeShellScript "disable-lid-wake.sh" ''
          echo LID0 >/proc/acpi/wakeup
        '';
      Type = "oneshot";
      RemainsAfterExit = true;
    };
  };
}
