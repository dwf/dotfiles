{ pkgs, ... }:
{
  programs.eza = {
    enable = true;
    icons = "auto";
    enableBashIntegration = true;
    extraOptions = [
      "-F"
      "--group-directories-first"
    ];
  };

  # Use this theme for ls -l output columns, ordinary colors are overridden
  # by LS_COLORS.
  xdg.configFile."eza/theme.yml".source =
    let
      eza-themes = pkgs.fetchFromGitHub {
        owner = "eza-community";
        repo = "eza-themes";
        rev = "74be26bbd2ce76b29c37250a2fb7cb5d6644c964";
        sha256 = "sha256-Gs21+A/to2AqjQsqMlWeOuSowYPOuSZ3fK6LRdBPUmI=";
      };
    in
    "${eza-themes}/themes/tokyonight.yml";
}
