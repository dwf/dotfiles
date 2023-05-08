# Options to try and minimize the image's size.
{ lib, ... }: {
  documentation.enable = lib.mkDefault false;
  fonts.fontconfig.enable = lib.mkDefault false;
  programs.command-not-found.enable = lib.mkDefault false;

  nixpkgs.overlays = [
    (self: super: {
      # We won't run X11 so won't need X11 support in dbus, and all the
      # dependencies that pulls in.
      dbus = super.dbus.override { x11Support = false; };

      # Disable a bunch of systemd features we definitely aren't using.
      systemd = super.systemd.override {
        withCryptsetup = false;
        withDocumentation = false;
        withFido2 = false;
        withTpm2Tss = false;
      };
    })
  ];

  # Enabled by default and pulls in a bunch of X11 dependencies.
  security.pam.services.su.forwardXAuth = lib.mkForce false;
}
