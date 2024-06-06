let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{ lib, ... }: {
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
  };

  home.sessionVariables.EDITOR = "nvim";
}
