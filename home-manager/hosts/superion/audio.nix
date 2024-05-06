{ inputs, ... }:
{
  xdg.configFile."easyeffects/output".source = inputs.framework-audio-presets.outPath;
}
