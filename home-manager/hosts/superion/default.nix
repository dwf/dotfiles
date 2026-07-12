{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../.
    ../../profiles/desktop/laptop.nix
    ../../profiles/wayland.nix
    ./audio.nix
    # `claude-vm` wrapper for the agentspace microVM (the apps it runs live
    # alongside in vms/agentspace/claude/apps.nix, imported by flake.nix).
    ../../../vms/agentspace/claude/wrappers.nix
  ];

  programs = {
    gh.enable = true;
    texlive = {
      enable = true;
      extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
    };
  };

  services.picom.vSync = true;

  nixpkgs.overlays = [
    inputs.niri-flake.overlays.niri
  ];

  home.packages = with pkgs; [
    calibre
  ];
}
