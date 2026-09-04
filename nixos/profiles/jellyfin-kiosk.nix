# Set-top box that boots straight into a fullscreen Jellyfin client.
#
# cage is a single-application Wayland kiosk: it autologs the given user on
# tty1, launches one program fullscreen, and restarts it if it exits. That is
# the entire "session" -- no display manager, no desktop.
{ pkgs, ... }:
let
  # Hide the pointer with a cursor theme whose every cursor is a fully
  # transparent image. Two consumers must both pick it up:
  #   * cage/wlroots renders the compositor cursor but ignores XCURSOR_THEME;
  #     with a NULL theme it hard-falls-back to the theme literally named
  #     "default" (wlroots xcursor.c), honouring only XCURSOR_PATH.
  #   * the Qt client draws its own cursor over its surface via libxcursor,
  #     which does read XCURSOR_THEME.
  # So the theme is named "default" (for wlroots) and also selected via
  # XCURSOR_THEME=default (for Qt). It must live on the *effective* XCURSOR_PATH:
  # pam_env resets XCURSOR_PATH to the session default at login, clobbering any
  # value set on the cage unit, so the theme is added to environment.systemPackages
  # instead -- landing in /run/current-system/sw/share/icons, which that session
  # path always includes. "left_ptr" is the primary cursor name; the rest are
  # aliased so nothing shows for any shape.
  blankCursorTheme =
    pkgs.runCommand "blank-cursor-theme"
      { nativeBuildInputs = [ pkgs.xcursorgen pkgs.imagemagick ]; }
      ''
        magick -size 24x24 xc:none blank.png
        echo "24 0 0 blank.png" > blank.config
        theme=$out/share/icons/default
        mkdir -p $theme/cursors
        xcursorgen blank.config $theme/cursors/left_ptr
        printf '[Icon Theme]\nName=default\n' > $theme/index.theme
        for n in default pointer hand hand1 hand2 text xterm ibeam crosshair \
                 cross wait watch progress move all-scroll not-allowed grab \
                 grabbing help; do
          ln -sf left_ptr $theme/cursors/$n
        done
      '';
in
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
      # Hide the pointer: load the transparent "default" theme (see above).
      # XCURSOR_PATH is not set here -- pam_env would overwrite it; the theme is
      # installed system-wide instead (environment.systemPackages below).
      XCURSOR_THEME = "default";
    };
  };

  # Put the transparent "default" cursor theme on the session's XCURSOR_PATH.
  environment.systemPackages = [ blankCursorTheme ];

  # nixos-rebuild reactivates autovt@tty1 (a getty), whose Conflicts= tears the
  # cage session down; because the cage module keeps restartIfChanged=false to
  # avoid killing the session, switch never brings it back and the box lands at
  # a console login. Disabling autovt on tty1 keeps the getty from ever
  # reclaiming the VT -- the same fix NixOS's greetd module applies. Config
  # changes to the session then apply on reboot (or `systemctl restart
  # cage-tty1`), which suits an appliance.
  systemd.services."autovt@tty1".enable = false;

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
