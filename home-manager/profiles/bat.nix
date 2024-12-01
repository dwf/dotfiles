{ pkgs, lib, ... }:
{
  programs.bat = {
    enable = true;
    config.theme = "tokyonight_moon";
    themes = let
      names = map (n: "tokyonight_${n}") [ "day" "moon" "night" "storm" ];
    in
    lib.genAttrs names (theme: {
      src = pkgs.vimPlugins.tokyonight-nvim;
      file = "extras/sublime/${theme}.tmTheme";
    });
  };
}
