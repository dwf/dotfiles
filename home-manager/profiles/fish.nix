{ pkgs, ... }:
{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = builtins.readFile "${pkgs.vimPlugins.tokyonight-nvim}/extras/fish/tokyonight_night.fish";
      plugins = [
        {
          name = "fzf.fish";
          src = pkgs.fetchFromGitHub {
            owner = "PatrickF1";
            repo = "fzf.fish";
            rev = "v10.3";
            sha256 = "sha256-T8KYLA/r/gOKvAivKRoeqIwE2pINlxFQtZJHpOy9GMM=";
          };
        }
      ];
    };
    fzf.enableFishIntegration = false;
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
}
