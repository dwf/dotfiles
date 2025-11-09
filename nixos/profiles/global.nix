# Config inherited by every single machine I manage with this repository.
{ lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Enable flakes.
  nix.extraOptions = "experimental-features = nix-command flakes";

  # Global useDHCP is deprecated.
  networking = {
    useDHCP = false;
    firewall.checkReversePath = "loose";
  };

  environment.systemPackages = with pkgs; [
    fd
    file
    git
    htop
    inetutils
    lsof
    pciutils
    psmisc
    ripgrep
    tmux
    tree
    usbutils
    unzip
    wget
    nfs-utils
    nix-tree
    wakeonlan
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
      "video" # webcam
      "dialout" # serial port
      "cdrom" # optical
      "audio" # midi
    ];
    useDefaultShell = lib.mkDefault true;
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdP+JZY3fGyoAz1iRO5NVMcc+L43qlrGwhqKoLZfeIq"
    ];
  };

  services = {
    sshd.enable = lib.mkDefault true;
    tailscale.enable = lib.mkDefault true;
    avahi = {
      enable = lib.mkDefault true;
      nssmdns4 = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };
  };
}
