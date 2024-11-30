{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile "${pkgs.vimPlugins.tokyonight-nvim}/extras/fish/tokyonight_night.fish";
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
}
