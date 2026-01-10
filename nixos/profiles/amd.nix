{ lib, pkgs, ... }:
{
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = lib.mkDefault true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        # Encoding/decoding acceleration
        libvdpau-va-gl
        libva-vdpau-driver
      ];
    };
  };
}
