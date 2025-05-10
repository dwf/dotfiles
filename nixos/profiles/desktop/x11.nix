{
  config,
  lib,
  pkgs,
  ...
}:
let
  X11 = config.services.xserver.enable;
in
with lib;
{
  services = {
    xserver = {
      enable = mkDefault true;
      xkb.layout = "us";
      displayManager.lightdm =
        let
          inherit (config.services.xserver) enable;
        in
        {
          inherit enable;
          greeters.gtk = {
            inherit enable;
          };
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
