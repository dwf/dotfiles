{ config, lib, ... }:

with lib;
let
  cfg = config.programs.neovim.lsp;
  curlySurround = s: "{ ${s} }";
  singleQuote = s: "'${s}'";
  luaStrList = l: curlySurround (concatMapStringsSep ", " singleQuote l);
  luaObj = o: curlySurround (
    concatStringsSep ", " (
      mapAttrsToList (k: v: "${k} = ${v}") o));
  simpleConfigOption = (n: v: ("${n} = " + (luaStrList v)));
  rootDir = (v: "root_dir = nvim_lsp.util.root_pattern(${luaStrList v})");
  configOption = (
    n:
    v:
    if n == "root_patterns" then
    (rootDir v)
    else
    (simpleConfigOption n v));
  configStr =
    c:
    curlySurround (
      "default_config = " + (
        curlySurround (
          concatStringsSep ", "
          (mapAttrsToList
            configOption
            (filterAttrs (s: _: s != "enable" && s != "onAttach") c)))));
  serverConfigs = concatStringsSep " " (
    mapAttrsToList
    (n: c: "configs.${n} = " + (configStr c))
    (filterAttrs (_: c: c.enable) cfg.servers));
  setKeyMapOptions = types.submodule {
    options = let
      mapOption = {
        type = with types; nullOr bool;
        default = null;
        example = "true";
      };
      opts = [ "noremap" "nowait" "silent" "script" "expr" "unique" ];
    in
    listToAttrs (
      (zipListsWith (name: value: { inherit name value; }))
      opts
      (map (_: mkOption mapOption) opts));
  };
  onAttachKeyMapping = types.submodule {
    options = {
      options = mkOption {
        type = types.nullOr setKeyMapOptions;
        default = null;
        example = "{ noremap = true; }";
        description = "Options passed to nvim_buf_set_keymap.";
      };
      command = mkOption {
        type = types.str;
        default = null;
        example = "<cmd>lua vim.lsp.buf.declaration()<CR>";
        description = "Lua command to invoke on key sequence.";
      };
      mode = mkOption {
        type = types.str;
        default = "n";
        example = "i";
        description = "Mode in which to define this key mapping.";
      };
    };
  };
  onAttachConfig = types.submodule {
    options = {
      defaultKeyMapOptions = mkOption {
        type = setKeyMapOptions;
        default = null;
        example = "{ noremap = true; }";
        description = (
          "The default options used for key mappings if a " +
          "value for a particular mapping is not specified.");
      };
      enableOmniFunc = mkEnableOption "Enable omni-complete.";
      keyMappings = mkOption {
        type = types.attrsOf onAttachKeyMapping;
        default = [];
        example =
          "{ gD = { " +
          "command = \"<cmd>lua vim.lsp.buf.declaration()<CR>\"; " +
          "} }";
        description = "Key mappings to define on attach.";
      };
      capabilities = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "require('cmp_nvim_lsp').update_capabilities(capabilities)";
        description = "String containing Lua expression to pass as " +
          "<literal>capabilities</literal> argument to call to " +
          "<literal>setup</literal>. This expression will usually reference " +
          "the already defined <literal>capabilities</literal> obtained " +
          "from Neovim's LSP implementation.";
      };
    };
  };
  setKeyMap = (
    defaultOpts:
    keys:
    m:
    let
      keyMapOpts = if isNull m.options then defaultOpts else m.options;
      boolToStr = (b: if b then "true" else "false");
      boolsToStrs = mapAttrs (_: v: boolToStr v);
      filterNull = filterAttrs (_: v: !isNull v);
    in
    "  vim.api.nvim_buf_set_keymap(bufnr, '${m.mode}', '${keys}', " +
    "'${m.command}', ${luaObj (boolsToStrs (filterNull keyMapOpts))})");
  maybeEnableOmniFunc =
    c:
    if c.enableOmniFunc then
    "vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')"
    else "";
  onAttachFn =
    name:
    conf:
    concatStringsSep "\n" ([
      "local ${name} = function(client, bufnr)"
      (maybeEnableOmniFunc conf)
    ] ++
    (mapAttrsToList (setKeyMap conf.defaultKeyMapOptions) conf.keyMappings) ++
    [
      # TODO(dwf): Make more configurable.
      "  vim.api.nvim_command(\"augroup lsp_highlighting\")"
      "  vim.api.nvim_command(\"autocmd!\")"
      "  if client.server_capabilities.document_highlight then"
      "    vim.api.nvim_command(\"autocmd CursorHold  <buffer> lua vim.lsp.buf.document_highlight()\")"
      "    vim.api.nvim_command(\"autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()\")"
      "    vim.api.nvim_command(\"autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()\")"
      "  end"
      "  vim.api.nvim_command(\"augroup END\")"
      "end"
    ]);
  lspServerConfig = types.submodule {
    options = {
      enable = mkEnableOption "Whether to enable this language server.";
      cmd = mkOption {
        type = with types; listOf str;
        default = null;
        example = "[ \"rnix-lsp\" ]";
        description = ''
          Command to execute to launch LSP server followed by any arguments.
        '';
      };
      filetypes = mkOption {
        type = with types; listOf str;
        default = null;
        example = ''
          [ "python" "c" "go" ]
        '';
        description = "File types for which to invoke this language server.";
      };
      root_patterns = mkOption {
        type = with types; listOf str;
        default = null;
        example = ''
          [ ".git" ]
        '';
        description = "";
      };
      settings = mkOption {
        type = with types; listOf str;
        default = [];
        example = "[}";
        description = "Additional settings for this LSP server config.";
      };
    };
  };
in
{
  options.programs.neovim.lsp = {
    enable = mkOption {
      type = types.bool;
      default = true;
      example = "false";
      description = "Whether to generate configuration for this LSP.";
    };
    servers = mkOption {
      type = types.attrsOf lspServerConfig;
      description = "LSP server configurations.";
    };
    onAttach = mkOption {
      type = onAttachConfig;
      default = null;
      example = "{}";
      description = "Configuration specifying buffer setup.";
    };
  };
  config = mkIf cfg.enable {
    programs.neovim.extraConfig =
      let
        capabilities =
          if (isNull cfg.onAttach.capabilities) then "capabilities"
          else cfg.onAttach.capabilities;
      in
    concatStringsSep "\n" [
      "lua << EOF"
      "-- Configuration for Neovim's built-in LSP support."
      "local nvim_lsp = require('lspconfig')"
      "local configs = require('lspconfig.configs')"
      "local capabilities = vim.lsp.protocol.make_client_capabilities()"
      ""
      serverConfigs
      ""
      (onAttachFn "on_attach" cfg.onAttach)
      ""
      "for _, lsp in pairs(${luaStrList (attrNames cfg.servers)}) do"
      "  require('lspconfig')[lsp].setup {"
      "    on_attach = on_attach,"
      "    capabilities = ${capabilities}"
      "  }"
      "end"
      "EOF"
    ];
  };
}
