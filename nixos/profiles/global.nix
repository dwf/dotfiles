# Config inherited by every single machine I manage with this repository.
{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Global useDHCP is deprecated.
  networking.useDHCP = false;

  environment.systemPackages = with pkgs; [
    fd
    git
    htop
    (neovim.override { vimAlias = true; })
    pciutils
    psmisc
    ripgrep
    tmux
    tree
    unzip
    wget
  ];

  time.timeZone = lib.mkDefault "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  services.sshd.enable = lib.mkDefault true;
  services.tailscale.enable = lib.mkDefault true;
}
