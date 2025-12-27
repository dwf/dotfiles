{ lib, pkgs, ... }:
let
  LS_COLORS = lib.strings.removeSuffix "\n" (
    builtins.readFile (
      pkgs.runCommand "ls-colors" { } "${pkgs.vivid}/bin/vivid generate tokyonight-moon >$out"
    )
  );
in
{
  programs = {
    bash.initExtra = ''export LS_COLORS="${LS_COLORS}"'';
    zsh.initContent = lib.mkOrder 550 ''export LS_COLORS="${LS_COLORS}"'';
    fish.interactiveShellInit = ''set -gx LS_COLORS "${LS_COLORS}"'';
  };

}
