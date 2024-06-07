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

    fzf = let
      defaultCommand = "fd --type f --strip-cwd-prefix --follow --exclude result";
    in {
      enable = lib.mkDefault true;
      enableBashIntegration = true;
      inherit defaultCommand;
      fileWidgetCommand = defaultCommand;

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
