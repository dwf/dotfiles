{ config, lib, pkgs, ... }:
let 
  X11 = config.services.xserver.enable;
in with lib; {
  services = {
    xserver = {
      enable = mkDefault true;
      xkb.layout = "us";
      displayManager.lightdm = {
        enable = config.services.xserver.enable;
        greeters.gtk.enable = true;
      };
    };

    # Defined in nixos/modules/user-xsession.nix
    displayManager = mkIf X11 {
      defaultSession = mkDefault "user-xsession";
    };
  };
  environment = mkIf X11 {
    systemPackages = with pkgs.xorg; [
      xdpyinfo
      xev
      xkill
    ];
  };
}
