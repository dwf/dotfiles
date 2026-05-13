{
  config,
  lib,
  pkgs,
  ...
}:
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
        cfg = (lib.foldl lib.attrsets.recursiveUpdate { }) [
          (mkPreset "no-empty-icons")
          (mkPreset "nerd-font-symbols")
          (readTOML ./tokyonight.toml)
          { opa.format = "'(via [$symbol($version )]($style))'"; } # Fix a typo in the no-empty-icons preset
          {
            directory.style = "bold blue";
            git_branch.style = "bold magenta";
            git_status.style = "bold cyan";
          }
        ];
        inherit (config.programs.starship.package) version;
      in
      if (builtins.compareVersions version "1.23.0") < 0 then
        (lib.removeAttrs cfg [
          "cpp"
          "fortran"
          "pixi"
          "xmake"
        ])
      else
        cfg;
  };
}
