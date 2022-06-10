{ pkgs, ... }:
{
  # We let the hostname get set by GCE.
  networking.interfaces.eth0.useDHCP = true;

  # Disable this service defined in google-compute-config.nix.
  systemd.services."fetch-instance-ssh-keys".enable = false;

  system.stateVersion = "21.11";
}
