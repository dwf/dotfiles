{ config, ... }:
{
  hardware.facetimehd.enable = true;
  nixpkgs.config.allowUnfree = true;
  boot = {
    kernelModules = [ "wl" ];
    extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
    blacklistedKernelModules = [ "b43" "bcma" ];
  };
}
