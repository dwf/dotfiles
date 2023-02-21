{ config, lib, ... }:

with lib;
let
  cfg = config.programs.vsnip;
  snippet = types.submodule {
    options = {
      description = mkOption {
        type = with types; nullOr str;
        default = null;
        description = "A natural language description of the snippet.";
      };
      body = mkOption {
        type = types.str;
        description = "String containing the snippet.";
      };
      prefix = mkOption {
        type = with types; listOf str;
        description = "List of strings which expand to this snippet.";
      };
    };
  };
in
{
  options.programs.vsnip = {
    enable = mkEnableOption "Snippets configuration for vim-vsnip.";
    snippets = mkOption {
      type = with types; attrsOf (attrsOf snippet);
      description = "Groups of snippets to be placed in JSON files.";
    };
  };
  config.home.file = let
    keyToFilename = key: ".vsnip/${key}.json";
    preprocessForJSON = { description, body, prefix }: {
      inherit prefix;
      body = splitString "\n" body;
    } // (optionalAttrs (! isNull description) { inherit description; });
    makeContents = attrs: {
      text = builtins.toJSON (mapAttrs (_: v: (preprocessForJSON v)) attrs);
    };
    snippetFile = k: v: nameValuePair (keyToFilename k) (makeContents v);
  in mkIf cfg.enable (mapAttrs' snippetFile cfg.snippets);
}
