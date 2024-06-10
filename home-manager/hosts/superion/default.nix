{ lib, pkgs, ... }:
let
  defaultAudioDevice = "alsa_output.pci-0000_c1_00.6.analog-stereo";
in {
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
        patches = old.patches ++ [
          (pkgs.substituteAll {
            src = ./swayosd-hardcode-easyeffects.patch;
            inherit defaultAudioDevice;
          })
        ];
      });
    })
  ];

  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
    XF86AudioMute = lib.mkForce "exec swayosd-client --output-volume mute-toggle --device ${defaultAudioDevice}";
    XF86AudioLowerVolume = lib.mkForce "exec swayosd-client --output-volume lower --device ${defaultAudioDevice}";
    XF86AudioRaiseVolume = lib.mkForce "exec swayosd-client --output-volume raise --device ${defaultAudioDevice}";
  };

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;
}
