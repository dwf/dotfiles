{ ... }:
{
  imports = [
    ../.
    ../../profiles/desktop/laptop.nix
    ../../profiles/wayland.nix
    ./audio.nix
  ];

  # TODO(dwf): Remove this when the bug is fixed upstream
  nixpkgs.overlays = [
    (self: super: {
      swayosd = super.swayosd.overrideAttrs (old: {
        # Hardcode the sink name I need as the command-line argument isn't 
        # actually fed through.
        patches = old.patches ++ [ ./swayosd-hardcode-easyeffects.patch ];
      });
    })
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;
}
