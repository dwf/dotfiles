{
  inputs,
  lib,
  pkgs,
  ...
}:
let
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
  home.file.".local/share/easyeffects/output".source = inputs.framework-audio-presets.outPath;

  services.easyeffects = {
    enable = true;
    preset = "lappy_mctopface";
  };

  programs.niri.settings.binds =
    # Controlling the default sink doesn't work when EasyEffects is enabled,
    # manually so specify the audio device.
    let
      defaultAudioDevice = "alsa_output.pci-0000_c1_00.6.analog-stereo";
      s = lib.splitString " ";
    in
    lib.mkAfter {
      "XF86AudioRaiseVolume".action.spawn =
        s "swayosd-client --output-volume raise --device ${defaultAudioDevice}";
      "XF86AudioLowerVolume".action.spawn =
        s "swayosd-client --output-volume lower --device ${defaultAudioDevice}";
      "XF86AudioMute".action.spawn =
        s "swayosd-client --output-volume mute-toggle --device ${defaultAudioDevice}";
      "Shift+XF86AudioLowerVolume".action.spawn = s "${toggleEasyEffects}";
      "Shift+XF86AudioRaiseVolume".action.spawn = s "sh ${profileSwitchScript}";
    };
}
