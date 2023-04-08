{
  imports = [ ../../../modules/vsnip.nix ];
  programs.vsnip = {
    enable = true;
    snippets.nix = {
      mkopt = {
        prefix = [ "mkopt" ];
        body = ''
          $${1:optionName} = mkOption {
            type = $${types.nonEmptyStr};
            example = "$${2:example value of this option}";
            description = "$${3:A description of this option.}";
          };
        '';
      };
    };
  };
}
