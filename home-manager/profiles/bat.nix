{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.bat = {
    enable = true;
    config.theme = "tokyonight_moon";
    themes =
      let
        names = map (n: "tokyonight_${n}") [
          "day"
          "moon"
          "night"
          "storm"
        ];
      in
      lib.genAttrs names (theme: {
        src = pkgs.vimPlugins.tokyonight-nvim;
        file = "extras/sublime/${theme}.tmTheme";
      });
  };

  home.sessionVariables = lib.mkIf config.programs.bat.enable {
    # https://github.com/sharkdp/bat/issues/3053#issuecomment-2259573578
    MANPAGER = ''
      sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'
    '';
  };
}
