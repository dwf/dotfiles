{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  defaultAudioDevice = "alsa_output.pci-0000_c1_00.6.analog-stereo";
  icon = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/wwmm/easyeffects/48a2a33c5495f92a44e0fa8697ccd3818cd9dded/data/com.github.wwmm.easyeffects.svg";
    hash = "sha256-1QUlD9vwCrfOwCSMoWvAGJzlC2tAXefsWvf73nEqmNU=";
  };
  profileSwitchScript = pkgs.replaceVars ./easyeffects-switch.sh {
    inherit icon;
  };
  toggleEasyEffects = pkgs.writeShellScript "toggle-easyeffects" ''
    if systemctl is-active --quiet --user easyeffects; then
      systemctl stop --user easyeffects
      notify-send --expire-time 1500 --icon ${icon} "EasyEffects" "Stopped EasyEffects service."
    else
      systemctl start --user easyeffects
      notify-send --expire-time 1500 --icon ${icon} "EasyEffects" "Started EasyEffects service."
    fi
  '';
in
{
  xdg.configFile."easyeffects/output".source = inputs.framework-audio-presets.outPath;

  services.easyeffects = {
    enable = true;
    preset = "lappy_mctopface";
  };

  # TODO(dwf): Remove this when the bug is fixed upstream
  nixpkgs.overlays = [
    (_: super: {
      swayosd = super.swayosd.overrideAttrs (old: {
        # Hardcode the sink name I need as the command-line argument isn't
        # actually fed through.
        patches = old.patches ++ [
          (pkgs.replaceVars ./swayosd-hardcode-easyeffects.patch {
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
    "Shift+XF86AudioLowerVolume" = "exec ${toggleEasyEffects}";
    "Shift+XF86AudioRaiseVolume" = "exec sh ${profileSwitchScript}";
  };
}
