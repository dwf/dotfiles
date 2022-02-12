{ pkgs, ... }:
let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{
  imports = [
    ../profiles/git.nix
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

    neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      plugins = with pkgs.vimPlugins; [
        vim-nix
        ctrlp
      ];
    };
  };

  home.sessionVariables.EDITOR = "nvim";
}
