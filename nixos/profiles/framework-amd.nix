{ lib, pkgs, ... }: {
  imports = [
    ./amd.nix
  ];
  boot.kernelParams = [
    "amd_pstate=active"
    # Removed: "amdgpu.ppfeaturemask=0xffffffff"
    "amdgpu.sg_display=0"
    "cpufreq.default_governor=powersave"
    "initcall_blacklist=cpufreq_gov_userspace_init,cpufreq_gov_performance_init"
    "pcie_aspm=force"
    "pc"
    "ie_aspm.policy=powersupersave"
  ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware = {
    # Workaround for nix-hardware module
    framework.amd-7040.preventWakeOnAC = true;

    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };

  powerManagement = {
    cpuFreqGovernor = lib.mkDefault "powersave";
    powertop.enable = true; # Run powertop on boot
  };

  services = {
    blueman.enable = true;
    fprintd.enable = true;
    power-profiles-daemon.enable = true;
    thermald.enable = true;

    fwupd = {
      enable = true;
      extraRemotes = [ "lvfs-testing" ]; # Some framework firmware is still in testing
    };
  };
}
