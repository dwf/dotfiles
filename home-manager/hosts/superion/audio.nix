{ inputs, ... }:
{
  xdg.configFile."easyeffects/output".source = inputs.framework-audio-presets.outPath;

  services.easyeffects = {
    enable = true;
    preset = "lappy_mctopface";
  };
}
