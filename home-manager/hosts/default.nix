{ lib, pkgs, ... }:
let
  forwardAgentHosts =
    let
      hosts = [
        "bumblebee"
        "cliffjumper"
        "kup"
        "perceptor"
        "shockwave"
        "soundwave"
        "wheeljack"
        "wreck-gar"
      ];
    in
    lib.concatStringsSep " " (hosts ++ (map (h: "${h}.local") hosts));
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
      enableDefaultConfig = false;
      matchBlocks = {
        "*".compression = true;
        "${forwardAgentHosts}" = {
          forwardAgent = true;
        };
      };
    };
  };

  home = {
    packages = [
      (pkgs.writeShellScriptBin "wol" (
        # You actually need this readFile as you need text, not a storepath reference, which is
        # what replaceVars will give you. So you end up with a script that just contains the
        # storepath, so it tries to execute that but it doesn't have the executable bit set.
        builtins.readFile (
          pkgs.replaceVars ../../scripts/wol.sh { wakeonlan = "${pkgs.wakeonlan}/bin/wakeonlan"; }
        )
      ))
    ];
    sessionVariables.EDITOR = "nvim";
    shellAliases.l = lib.mkDefault "ls";
  };
}
