{ config, lib, pkgs, ... }:

{
  imports = [
    ../.
    ../../profiles/x11/laptop.nix
  ];

  programs.keychain = {
    enable = true;
    enableBashIntegration = true;
    enableXsessionIntegration = true;
    agents = [ "ssh" ];
    keys = [ "id_ed25519" ];
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;
}
