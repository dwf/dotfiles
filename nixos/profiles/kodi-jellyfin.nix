# Set-top box running Kodi -- a real 10-foot media UI -- with the Jellyfin
# add-on. Kodi renders directly on KMS/DRM via kodi-gbm, run as a systemd
# service on tty1: no X server, no Wayland compositor, no display manager.
{ pkgs, ... }:
let
  # jellyfin-for-kodi (native sync: the Jellyfin library folds into Kodi's own
  # views). Swap `jellyfin` for `jellycon` for the lighter browse-only add-on.
  kodi = pkgs.kodi-gbm.withPackages (ps: [ ps.jellyfin ]);
in
{
  # Dedicated unprivileged account for the Kodi session.
  users.users.kodi = {
    isNormalUser = true;
    description = "Kodi";
    extraGroups = [
      "audio"
      "video"
      "render" # GPU / DRM render node
      "input" # keyboard, remotes, game controllers
      "cdrom"
    ];
  };

  systemd.services.kodi = {
    description = "Kodi media center (GBM)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-user-sessions.service"
      "network-online.target"
      "sound.target"
    ];
    wants = [ "network-online.target" ];
    conflicts = [ "getty@tty1.service" ];
    serviceConfig = {
      User = "kodi";
      Group = "users";
      # A full PAM/logind session gives the process seat0 -- hence DRM master
      # for KMS output and access to the seat's input devices.
      PAMName = "login";
      TTYPath = "/dev/tty1";
      StandardInput = "tty";
      StandardOutput = "journal";
      StandardError = "journal";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      ExecStart = "${kodi}/bin/kodi-standalone";
      Restart = "always";
      RestartSec = "5s";
    };
  };

  # Keep the getty/autovt off Kodi's tty so a nixos-rebuild doesn't drop the
  # box to a console login by fighting Kodi for VT ownership.
  systemd.services."autovt@tty1".enable = false;

  # Let Kodi power off / reboot / suspend from its UI without a password prompt.
  security.polkit = {
    enable = true;
    extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id.indexOf("org.freedesktop.login1.") === 0 && subject.user === "kodi") {
          return polkit.Result.YES;
        }
      });
    '';
  };

  # Hardware-accelerated video decode on the Intel iGPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # Audio out.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
}
