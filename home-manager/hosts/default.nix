{ pkgs, ... }:
let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{
  imports = [
    ../profiles/git.nix
    ../profiles/neovim
  ];

  nixpkgs.config.allowUnfree = true;

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

  home.sessionVariables.EDITOR = "nvim";
}
