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
    # `claude-vm`/`agy-vm` wrappers for the agentspace microVMs (the apps
    # they run live alongside in vms/agentspace/<name>/apps.nix, imported by
    # flake.nix).
    ../../../vms/agentspace/claude/wrappers.nix
    ../../../vms/agentspace/agy/wrappers.nix
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
