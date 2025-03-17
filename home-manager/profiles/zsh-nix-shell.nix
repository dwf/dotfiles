{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.zsh;
in
{
  programs = {
    zsh.plugins = [
      # Drop into zsh with `nix develop` by default. Requires bash setup below.
      {
        name = "simple-zsh-nix-shell";
        src = pkgs.fetchFromGitHub {
          owner = "goolord";
          repo = "simple-zsh-nix-shell";
          rev = "f8b82db8b4a4d4a3d31d43697e590207eca29da1";
          sha256 = "sha256-lOf5IlToVvh8VqmGthwT2yAhSNxd/0sO2Edzpgh24Ao=";
        };
        file = "simple-zsh-nix-shell.plugin.zsh";
      }
    ];
    bash.initExtra =
      lib.mkIf cfg.enable # bash
        ''
          if [ ! -z ''${SIMPLE_ZSH_NIX_SHELL_BASH+x} ] ;
            then source $SIMPLE_ZSH_NIX_SHELL_BASH
          fi
        '';
  };
}
