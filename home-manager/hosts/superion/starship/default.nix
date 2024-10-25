{ lib, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings =
      let
        # TODO: generate these with "starship preset" as part of the build.
        # At least the no-empty-icons preset has a typo that needs to be fixed
        # manually.
        formats = builtins.fromTOML (builtins.readFile ./no-empty.toml);
        symbols = builtins.fromTOML (builtins.readFile ./symbols.toml);
      in
      lib.attrsets.recursiveUpdate formats symbols;
  };
}
