let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{ lib, ... }:
{
  imports = [
    ../profiles/bat.nix
    ../profiles/eza.nix
    ../profiles/git.nix
    ../profiles/tmux
    ../profiles/vivid.nix
    ../../overlays/eza.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Work around NixOS/nixpkgs#171810
  nixpkgs.config.allowUnfreePredicate = _: true;

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

    };
  };
}
