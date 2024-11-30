{ lib, pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings =
      let
        readTOML = fn: builtins.fromTOML (builtins.readFile fn);
        mkPreset =
          name:
          readTOML (
            pkgs.runCommand "starship-preset-${name}.toml" { }
              "${pkgs.starship}/bin/starship preset ${name} --output $out"
          );
      in
      (lib.foldl lib.attrsets.recursiveUpdate { }) [
        (mkPreset "no-empty-icons")
        (mkPreset "nerd-font-symbols")
        (readTOML ./tokyonight.toml)
        { opa.format = "'(via [$symbol($version )]($style))'"; } # Fix a typo in the no-empty-icons preset
      ];
  };
}
