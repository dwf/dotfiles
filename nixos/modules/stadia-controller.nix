{ config, lib, ... }:
let
  cfg = config.hardware.stadiaController;
in with lib;
{
  options.hardware.stadiaController.enable = (
    mkEnableOption "Enable udev rules required for Stadia controller.");

  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      # Copied verbatim from Google's instructions on the Stadia website.
      KERNEL=="hidraw*", ATTRS{idVendor}=="1fc9", MODE="0666"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1fc9", MODE="0666"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", MODE="0666"
      # Flashloader
      KERNEL=="hidraw*", ATTRS{idVendor}=="15a2", MODE="0666"
      # Controller
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="18d1", MODE="0666"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9400", MODE="0660", TAG+="uaccess"
    '';
  };
}
