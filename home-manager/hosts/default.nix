{ lib, ... }:
let
  forwardAgentHosts = lib.concatStringsSep " " [
    "bumblebee"
    "cliffjumper"
    "perceptor"
    "shockwave"
    "wheeljack"
  ];
in
{
  imports = [
    ../profiles/bat.nix
    ../profiles/eza.nix
    ../profiles/fzf
    ../profiles/git.nix
    ../profiles/starship
    ../profiles/tmux
    ../profiles/vivid.nix
    ../profiles/zoxide.nix
    ../profiles/zsh.nix
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
