{ config, lib, pkgs, ... }:
{
  xsession = {
    windowManager.i3.config = {
      keybindings = lib.mkOptionDefault (import ../i3-sway-common.nix { inherit config lib pkgs; }).function-keys;
    };
  };
}
