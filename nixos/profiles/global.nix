# Config inherited by every single machine I manage with this repository.
{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Switch to Nix unstable and enable flakes.
  nix.package = pkgs.nixUnstable;
  nix.extraOptions = "experimental-features = nix-command flakes";

  # Global useDHCP is deprecated.
  networking.useDHCP = false;

  environment.systemPackages = with pkgs; [
    fd
    git
    htop
    (neovim.override { vimAlias = true; })
    nix-tree
    pciutils
    psmisc
    ripgrep
    tmux
    tree
    usbutils
    unzip
    wget
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    efi = {
      canTouchEfiVariables = lib.mkDefault true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  time.timeZone = lib.mkDefault "Europe/London";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.dwf = {
    createHome = true;
    home = "/home/dwf";
    description = "David Warde-Farley";
    group = "users";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"           # webcam
      "dialout"         # serial port
      "cdrom"           # optical
    ];
    useDefaultShell = true;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICk0JK209eN5l4DACxfOvW4aR7eESUF/9M5aBCSSPXx6"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINbaGkERCWcjTDdNxo2kAqQHbxjdEVYFrCVtOkRHA2Xd"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJIu/+NQfyBa+6QERqqYIvK3sXN3eSLOWfPJKSm1dFg45Qiec43dPdKF/vk0oUWbriplOEgzShRJWQL6py0oepY="
    ];
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
