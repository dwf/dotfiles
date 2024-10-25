let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{ lib, ... }:
{
  imports = [
    ../profiles/git.nix
    ../profiles/tmux
  ];

  nixpkgs.config.allowUnfree = true;

  # Work around NixOS/nixpkgs#171810
  nixpkgs.config.allowUnfreePredicate = (pkg: true);

  programs = {
    home-manager.enable = true;

    bash.enable = true;

    fzf = {
      enable = lib.mkDefault true;
      enableBashIntegration = true;
    };

    ssh = {
      enable = true;
      compression = true;
      matchBlocks = {
        "${forwardAgentHosts}" = {
          forwardAgent = true;
        };
      };
    };

    eza = {
      enable = true;
      enableBashIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = [ "--cmd cd" ];
    };
  };

  home = {
    sessionVariables.EDITOR = "nvim";
    shellAliases = {
      # Also alias the original zoxide commands, to see how I get on with them.
      z = "cd";
      zi = "cdi";
      ls = "eza --icons=auto -F";
      ll = "eza -l --icons=auto -F";

    };
  };
}
