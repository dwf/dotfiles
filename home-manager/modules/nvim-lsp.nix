{ config, lib, ... }:

with lib;
let
  cfg = config.programs.neovim.lsp;
  lspServerConfig = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        example = "false";
        description = ''
          Whether to enable this language server. Defaults to true.
          Useful to override for derived configs.
        '';
      };
      cmd = mkOption {
        type = with types; nonEmptyListOf nonEmptyStr;
        default = null;
        example = "[ \"rnix-lsp\" ]";
        description = ''
          Command to execute to launch LSP server followed by any arguments.
        '';
      };
      filetypes = mkOption {
        type = with types; nullOr (nonEmptyListOf nonEmptyStr);
        default = null;
        example = ''
          [ "python" "c" "go" ]
        '';
        description = "File types for which to invoke this language server.";
      };
      rootPatterns = mkOption {
        type = with types; nullOr (nonEmptyListOf nonEmptyStr);
        default = null;
        example = ''
          [ ".git" ]
        '';
        description = "Files that demarcate the root directory of a project.";
      };
      capabilities = mkOption {
        type = with types; nullOr nonEmptyStr;
        default = null;
        example = "require('cmp_nvim_lsp').default_capabilities()";
        description = ''
          String containing Lua expression to pass as
          <literal>capabilities</literal> argument to call to
          <literal>setup</literal>.
        '';
      };
      settings = mkOption {
        type = with types; nullOr attrs;
        default = null;
        example = "[}";
        description = ''
          Additional settings for this LSP server config. Rendered as JSON,
          so needs to be in the overlapping dialect of JSON and Lua. If you
          need to use unquoted Lua identifiers, use <literal>extraLua</literal>
          instead.
        '';
      };
      extraLua = mkOption {
        type = types.lines;
        default = "";
        example = "settings = {}";
        description = ''
          Additional lines of Lua inside the call to setup. Use when the above
          options are insufficiently flexible.
        '';
      };
    };
  };
in {
  options.programs.neovim.lsp = {
    enable = mkEnableOption "LSP configuration for Neovim.";
    servers = mkOption {
      type = types.attrsOf lspServerConfig;
      description = "LSP server configurations.";
    };
  };
  config = mkIf cfg.enable {
    programs.neovim.extraConfig = ''
      lua << EOF
    '' + concatStringsSep "\n" (
      mapAttrsToList (name: serverConfig: with lib.strings; let
        luaList = l: ''{ ${concatMapStringsSep ", " escapeNixString l} }'';
        formattedArg = argName: let
          correctedArgName =  # TODO(dwf): There's gotta be a camel->snake in stdlib
            if argName == "rootPatterns" then "root_patterns" else argName;
            arg = getAttr argName serverConfig;
        in "  ${correctedArgName} = ${luaList arg},";
        capabilities = optionalString (! isNull serverConfig.capabilities)
          "  capabilities = ${serverConfig.capabilities},";
        optionalArg = argName: optional
          (! isNull (getAttr argName serverConfig))
          (formattedArg argName);
      in concatStringsSep "\n" ([
         ''
         require('lspconfig').${name}.setup {
           cmd = ${luaList serverConfig.cmd},
         }
         ''
      ] ++
      (optional (! isNull serverConfig.capabilities) capabilities) ++
      (optionalArg "filetypes") ++
      (optionalArg "rootPatterns") ++
      (optionalArg "settings") ++
      (optionals (! isNull serverConfig.extraLua)
        (map (s: "  ${s}") (splitString "\n" serverConfig.extraLua))))
      ) (filterAttrs (_: server: server.enable) cfg.servers) ++ [ "EOF" ]
    );
  };
}
