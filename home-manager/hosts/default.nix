{ lib, ... }:
let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{
  imports = [
    ../profiles/bat.nix
    ../profiles/eza.nix
    ../profiles/fzf
    ../profiles/git.nix
    ../profiles/tmux
    ../profiles/vivid.nix
    ../profiles/zoxide.nix
    ../../overlays/eza.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Work around NixOS/nixpkgs#171810
  nixpkgs.config.allowUnfreePredicate = _: true;

  programs = {
    home-manager.enable = true;

    bash.enable = true;

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

  home = {
    sessionVariables.EDITOR = "nvim";
    shellAliases.l = lib.mkDefault "ls";
  };
}
