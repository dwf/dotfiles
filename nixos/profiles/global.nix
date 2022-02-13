# Config inherited by every single machine I manage with this repository.
{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Switch to Nix 2.4 and enable flakes.
  nix.package = pkgs.nix_2_4;
  nix.extraOptions = "experimental-features = nix-command flakes";

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
    usbutils
    unzip
    wget
  ];

  time.timeZone = lib.mkDefault "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.dwf = {
    createHome = true;
    home = "/home/dwf";
    description = "David Warde-Farley";
    group = "users";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    useDefaultShell = true;
    isNormalUser = true;
  };

  services.sshd.enable = lib.mkDefault true;
  services.tailscale.enable = lib.mkDefault true;
  services.avahi = {
    enable = lib.mkDefault true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

}
