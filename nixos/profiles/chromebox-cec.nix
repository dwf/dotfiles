# HDMI-CEC on ChromeOS hardware (e.g. the wreck-gar Chromebox): CEC is bridged
# through the ChromeOS Embedded Controller, not the Intel HDMI block, so the
# driver is CEC_CROS_EC. The stock nixpkgs kernel ships CEC_CORE and CROS_EC as
# modules but leaves MEDIA_CEC_SUPPORT off, which gates every CEC device driver
# -- including CEC_CROS_EC. Turning it on is a kernel config change, hence a
# kernel rebuild (best done on a remote builder; this box is slow).
{ lib, pkgs, ... }:
{
  boot.kernelPatches = [
    {
      name = "cros-ec-cec";
      patch = null;
      structuredExtraConfig = with lib.kernel; {
        MEDIA_CEC_SUPPORT = yes;
        CEC_CROS_EC = module;
      };
    }
  ];

  # The CEC bridge is instantiated by the cros_ec MFD, but load it explicitly.
  boot.kernelModules = [ "cros-ec-cec" ];

  # cec-ctl / cec-follower for inspecting and testing the adapter.
  environment.systemPackages = [ pkgs.v4l-utils ];

  # Kodi's libcec opens /dev/cecN, which is root-only by default. Grant the
  # "video" group access (the kodi user is a member).
  services.udev.extraRules = ''
    KERNEL=="cec[0-9]*", GROUP="video", MODE="0660"
  '';
}
