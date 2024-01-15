{ lib, pkgs, ... }:
{
  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
    opengl = {
      driSupport = lib.mkDefault true;
      driSupport32Bit = lib.mkDefault true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        amdvlk
        # Encoding/decoding acceleration
        libvdpau-va-gl
        vaapiVdpau
      ];
      extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
    };
  };
}
