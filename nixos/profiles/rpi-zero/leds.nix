{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.hardware.leds;
in {
  options.hardware.leds = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        trigger = mkOption {
          type = types.nonEmptyStr;
          example = "default-on";
          description = ''
            Desired trigger for the given LED. See the value of
            /sys/class/leds/<LED NAME>/trigger.
          '';
        };
      };
    });
    description = ''
      An attrset where the names are entries under /sys/class/leds
      and values are the configuration for that LED.
    '';
  };
  config.systemd.services =
    let
      mkService = name: ledConfig: nameValuePair "led-${name}" ({
        enable = true;
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = pkgs.writeShellScript "led-${name}-set-trigger.sh" ''
            echo ${ledConfig.trigger} >/sys/class/leds/${name}/trigger
          '';
          Type = "oneshot";
        };
      });
    in mapAttrs' mkService cfg;
}
