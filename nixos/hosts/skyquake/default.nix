{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;

  # Switch to Nix 2.4 and enable flakes.
  nix.package = pkgs.nix_2_4;
  nix.extraOptions = ''
  experimental-features = nix-command flakes
  '';

  networking.hostName = "skyquake";

  # Global useDHCP is deprecated.
  networking.useDHCP = false;

  # Do not also set an interface's useDHCP = true unless you want them to get
  # into a fight.
  networking.networkmanager.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/London";

  # The hardware scan enabled the correct WiFi module. Prohibit the impostors.
  boot.blacklistedKernelModules = [ "b43" "bcma" ];

  # Spin up the CPU frequency less quickly, sparing the battery.
  powerManagement.cpuFreqGovernor = "conservative";

  services.tailscale.enable = true;

  # SSD with full disk encryption (except for boot EFI), including swap.
  fileSystems = {
    "/".options = [ "noatime" "compress=lzo" "autodefrag" "commit=100" ];
    "/home".options = [ "noatime" "compress=lzo" "autodefrag" ];
  };
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # The hardware scan was smart enough to add the swap device but not smart
  # enough to add the LUKS mapper for it.
  boot.initrd.luks.devices.cryptswap.device = "/dev/sda2";

  # Backlight control from the command line.
  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    fd
    git
    lm_sensors
    psmisc
    ripgrep
    tmux
    vim
    wget
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
  };

  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  services.xserver = {
    enable = true;
    layout = "us";
    libinput = {
      enable = true;
      touchpad.tapping = false;
    };
    displayManager = {
      lightdm = {
        enable = true;
        greeters.gtk = {
          enable = true;

          # Fix for tiny cursor on HiDPI display in the display manager.
          # There's a separate fix in home config for once we're logged in.
          cursorTheme.size = 32;
          extraConfig = "xft-dpi = 192";
        };
      };

      # Adds a custom session that just spins up my home-manager ~/.xsession.
      session = [
        {
          manage = "desktop";
          name = "xsession";
          start = ''exec $HOME/.xsession'';
        }
      ];

      defaultSession = "xsession";
    };
  };

  users.users.dwf = {
    createHome = true;
    home = "/home/dwf";
    description = "David Warde-Farley";
    group = "users";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    useDefaultShell = true;
    isNormalUser = true;
  };

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Flatpak (for e.g. Steam).
  services.flatpak.enable = true;
  services.accounts-daemon.enable = true;
  xdg.portal.enable = true;
  hardware.opengl.driSupport32Bit = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
