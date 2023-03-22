{ config, lib, ... }:

with lib;
let
  cfg = config.programs.neovim.lsp;
  camelToSnake =
    builtins.replaceStrings upperChars (map (c: "_${c}") lowerChars);
  asLua = arg: let
    curlies = s: "{" + s + "}";
    handlers = {
      bool = toString;
      int = toString;
      float = toString;
      list = l: curlies (concatMapStringsSep ", " asLua l);
      null = _: "nil";
      set = s: curlies (concatStringsSep ", "
        (mapAttrsToList (n: v: "${n} = ${asLua v}") s));
      string = lib.strings.escapeNixString;
    };
  in (getAttr (builtins.typeOf arg) handlers) arg;
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
      name = mkOption {
        type = with types; nullOr nonEmptyStr;
        default = null;
        example = "pyright";
        description = "Name for the LSP. Defaults to the definition key.";
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
      singleFileSupport = mkOption {
        type = with types; nullOr bool;
        default = null;
        example = "true";
        description = ''
          Determines if a server is started without a matching root directory.
        '';
      };
      rootDir = mkOption {
        type = with types; nullOr nonEmptyStr;
        default = null;
        example = "require('lspconfig').util.find_git_ancestor";
        description = "Lua function that locates the project root.";
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
        example = "{}";
        description = ''
          Additional settings for this LSP server config.
        '';
      };
      extraLua = mkOption {
        type = types.lines;
        default = "";
        example = "settings = {}";
        description = ''
          Additional lines of Lua inside the call to setup. Should be
          comma-separated arg = value pairs. Use when the above options are
          insufficiently flexible.
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
        literalLuaArg = argName: let
          arg = getAttr argName serverConfig;
        in optional (! isNull arg) "  ${argName} = ${arg},";
        nixArg = argName: let
          arg = getAttr argName serverConfig;
        in optional (! isNull arg) "  ${camelToSnake argName} = ${asLua arg},";
      in concatStringsSep "\n" (
        [ "require('lspconfig').${name}.setup {" ] ++
        (nixArg "name") ++
        (nixArg "cmd") ++
        (literalLuaArg "capabilities") ++
        (literalLuaArg "rootDir") ++
        (nixArg "filetypes") ++
        (nixArg "settings") ++
        (optionals (! isNull serverConfig.extraLua) (map (s: "  ${s}") (splitString "\n" serverConfig.extraLua))) ++
        [ "}" ])
      ) (filterAttrs (_: server: server.enable) cfg.servers) ++ [ "EOF" ]
    );
  };
}
