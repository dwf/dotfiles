# Set-top box that boots straight into a fullscreen Jellyfin client.
#
# cage is a single-application Wayland kiosk: it autologs the given user on
# tty1, launches one program fullscreen, and restarts it if it exits. That is
# the entire "session" -- no display manager, no desktop.
{ lib, pkgs, ... }:
let
  # cage/wlroots always renders a pointer cursor (parked at screen centre with
  # no mouse attached) and has no flag to hide it. The portable trick is a
  # cursor theme whose every cursor is a fully transparent image, selected via
  # XCURSOR_THEME. "left_ptr" is the name cage draws by default; the rest are
  # aliased so nothing shows even if the web view requests another shape.
  blankCursorTheme =
    pkgs.runCommand "blank-cursor-theme"
      { nativeBuildInputs = [ pkgs.xorg.xcursorgen pkgs.imagemagick ]; }
      ''
        magick -size 24x24 xc:none blank.png
        echo "24 0 0 blank.png" > blank.config
        theme=$out/share/icons/blank
        mkdir -p $theme/cursors
        xcursorgen blank.config $theme/cursors/left_ptr
        printf '[Icon Theme]\nName=blank\n' > $theme/index.theme
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
      # Hide the pointer: point the cursor loader at the transparent theme.
      XCURSOR_THEME = "blank";
      XCURSOR_PATH = "${blankCursorTheme}/share/icons";
    };
  };

  # The upstream cage module sets restartIfChanged=false, so a rebuild that
  # lets a getty reclaim tty1 (via the conflicts= relationship) leaves the box
  # at a console login instead of the kiosk. On an appliance we'd rather a
  # switch just relaunch the client and land back in Jellyfin.
  systemd.services.cage-tty1.restartIfChanged = lib.mkForce true;

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
