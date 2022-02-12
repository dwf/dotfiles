{ pkgs, ... }:
let
  forwardAgentHosts = "shockwave wheeljack bumblebee cliffjumper";
in
{
  nixpkgs.config.allowUnfree = true;

  programs = {
    home-manager.enable = true;

    bash.enable = true;

    git = {
      enable = true;
      userName = "David Warde-Farley";
      userEmail = builtins.concatStringsSep "@" [
        "dwf"
        (builtins.concatStringsSep "." [ "google" "com" ])
      ];
      aliases = {
        ca = "commit -a";
        co = "checkout";
        st = "status -a";
        ap = "add -p";
        record = "add -p";
      };
      ignores = [ ".*.swp" "tags" ".ropeproject" ".netrwhist" ];
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
