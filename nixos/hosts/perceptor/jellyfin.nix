# Jellyfin media server, running in an isolated NixOS container.
#
# The container has its own private network (10.233.51.2), reachable only via
# the host. Media is served from a Synology NFS export mounted on the host and
# bind-mounted into the container read-only. The host's Intel N100 iGPU is
# passed through for QuickSync hardware transcoding (HEVC/H.264 encode, plus
# AV1/HEVC/VP9/H.264 decode).
#
# Access is via the host's Tailscale HTTPS reverse proxy (see default.nix),
# which forwards to the container's Jellyfin on :8096.
{ ... }:
let
  hostAddress = "10.233.51.1";
  localAddress = "10.233.51.2";
  # Where the Synology library export is mounted on the host.
  mediaHostPath = "/mnt/jellyfin";
in
{
  # NFS library share from the Synology. nofail so the host still boots if the
  # NAS is unavailable (e.g. before it exists); soft mount avoids hung I/O.
  # The container is ordered after this mount below.
  # XXX: If the NAS comes up *after* the container starts, the bind mount will
  # show empty until `systemctl restart container@jellyfin`.
  fileSystems.${mediaHostPath} = {
    device = "10.0.10.10:/volume1/jellyfin";
    fsType = "nfs";
    options = [
      "nfsvers=4.1"
      "soft"
      "timeo=150"
      "retrans=3"
      "nofail"
      "_netdev"
      "x-systemd.after=network-online.target"
    ];
  };

  # Masquerade the container's private network out over the LAN interface so
  # Jellyfin can reach the internet (metadata, plugin updates).
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp1s0";
  };

  # Ensure the media mount is attempted before the container starts. `wants`
  # (not `requires`) so the container still comes up if the NAS is down.
  systemd.services."container@jellyfin" = {
    after = [ "mnt-jellyfin.mount" ];
    wants = [ "mnt-jellyfin.mount" ];
  };

  containers.jellyfin = {
    autoStart = true;
    privateNetwork = true;
    inherit hostAddress localAddress;

    bindMounts = {
      # Media library, read-only.
      "/media" = {
        hostPath = mediaHostPath;
        isReadOnly = true;
      };
      # iGPU render node for QuickSync transcoding.
      "/dev/dri" = {
        hostPath = "/dev/dri";
        isReadOnly = false;
      };
    };

    # Allow the container to open the DRM render/card devices.
    allowedDevices = [
      {
        node = "/dev/dri/renderD128";
        modifier = "rw";
      }
      {
        node = "/dev/dri/card0";
        modifier = "rw";
      }
    ];

    config =
      { config, pkgs, ... }:
      {
        services.jellyfin = {
          enable = true;
          openFirewall = true;
        };

        # VAAPI / QuickSync userspace for the N100 (Gen12 Xe-LP).
        hardware.graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver # iHD VAAPI driver (Gen8+)
            vpl-gpu-rt # oneVPL runtime for QSV
          ];
        };

        # Jellyfin needs access to the render node.
        # XXX: Verify the `render` group GID matches the host's ownership of
        # /dev/dri/renderD128 on first boot; a mismatch silently disables
        # hardware transcoding. Check with `stat -c %g /dev/dri/renderD128`
        # inside and outside the container and pin the GID if they differ.
        users.users.jellyfin.extraGroups = [
          "video"
          "render"
        ];

        environment.systemPackages = with pkgs; [
          intel-gpu-tools # `intel_gpu_top` for verifying transcode offload
          libva-utils # `vainfo` to confirm the codec profiles
        ];

        system.stateVersion = "24.11";
      };
  };
}
