{ lib, pkgs, ... }: {
  hardware.firmware = with pkgs; [ raspberrypiWirelessFirmware ];
  environment.systemPackages = with pkgs; [ wirelesstools wpa_supplicant ];
}
