# Set-top box that boots straight into a fullscreen Jellyfin client.
#
# cage is a single-application Wayland kiosk: it autologs the given user on
# tty1, launches one program fullscreen, and restarts it if it exits. That is
# the entire "session" -- no display manager, no desktop.
{ pkgs, ... }:
{
  # Dedicated unprivileged account for the kiosk session: no wheel, no
  # networkmanager, no login password -- cage autologins it on tty1. Only the
  # groups needed to reach the GPU (video/render) and audio devices.
  users.users.kiosk = {
    isNormalUser = true;
    description = "Jellyfin kiosk";
    extraGroups = [
      "audio"
      "video"
      "render"
    ];
  };

  services.cage = {
    enable = true;
    user = "kiosk";
    # --tv selects Jellyfin's 10-foot "TV" interface; cage already fullscreens
    # the surface but --fullscreen keeps the client's own state consistent.
    program = "${pkgs.jellyfin-media-player}/bin/jellyfin-desktop --tv --fullscreen";
    environment = {
      # Qt client prefers native Wayland, falling back to XWayland (cage ships
      # an XWayland server) if the platform plugin is unavailable.
      QT_QPA_PLATFORM = "wayland;xcb";
      # cage doesn't advertise xdg-decoration, so Qt draws its own titlebar
      # (client-side decorations). Suppress it so the surface is borderless.
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    };
  };

  # Hardware-accelerated video decode on the Intel iGPU for mpv playback.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # Audio out for playback.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
}
