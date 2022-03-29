{ pkgs, ... }:
{
  # We let the hostname get set by GCE.
  networking.interfaces.eth0.useDHCP = true;

  imports = [
    <nixpkgs/nixos/modules/virtualisation/google-compute-image.nix>
  ];
}
