{ pkgs, ... }:
{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = builtins.readFile "${pkgs.vimPlugins.tokyonight-nvim}/extras/fish/tokyonight_night.fish";
      plugins = with pkgs.fishPlugins; [
        {
          name = "fzf.fish";
          inherit (fzf-fish) src;
        }
      ];
    };
    fzf.enableFishIntegration = false;
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
}
