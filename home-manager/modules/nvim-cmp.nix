{ config, lib, ... }:

with lib;
let
  lua = import ../lib/lua.nix { inherit lib; };
  cfg = config.programs.neovim.pluginConfig.nvim-cmp;
  defaultNullOrIntOption = description: mkOption {
    inherit description;
    type = with types; nullOr int;
    default = null;
    example = "2";
  };
  defaultNullOrBoolOption = description: mkOption {
    inherit description;
    type = with types; nullOr bool;
    default = null;
    example = true;
  };
in {
  options.programs.neovim.pluginConfig.nvim-cmp = {
    enable = mkEnableOption "Enable configuration of nvim-cmp.";
    keyMappings = mkOption {
      type = with types; attrsOf nonEmptyStr;
      default = {};
      description = ''
        An attribute set of key mappings to be added to nvim-cmp.

        Each key should be a string specifying the key mapping, and the value
        should be a string specifying the Lua code to be executed when the key
        mapping is triggered. See the nvim-cmp documentation for more information.
      '';
    };
    sorting = mkOption {
      type = with types; nullOr (types.submodule {
        options = {
          priorityWeight = defaultNullOrIntOption ''
            Priority weight for completions. See nvim-cmp documentation for details.
          '';
          comparators = mkOption {
            type = nullOr (listOf string);
            default = null;
            example = ''
              [ "cmp.config.compare.kind" "cmp.config.compare.recently_used" ]
            '';
            description = ''
              An ordered list of strings representing comparison functions.
            '';
          };
        };
      });
      default = null;
      description = "Sorting options. See nvim-cmp documentation for details.";
    };
    sources = mkOption {
      type = with types; nonEmptyListOf (submodule {
        options = {
          name = mkOption {
            type = types.nonEmptyStr;
            description = "The name of the source.";
          };
          priority = defaultNullOrIntOption "The priority of the source.";
          maxItemCount = defaultNullOrIntOption ''
            The maximum number of items to be displayed for the source.
          '';
          groupIndex = defaultNullOrIntOption ''
            The index of the group to which the source belongs.
          '';
          keywordLength = defaultNullOrIntOption ''
            Minimum length of token to offer as completion.
          '';
        };
      });
      default = [
        { name = "nvim_lsp"; }
        { name = "buffer"; }
        { name = "path"; }
      ];
      description = ''
        A list of sources to enable for nvim-cmp.

        Each item in the list should be an attribute set with a `name` key
        specifying the name of the source. Other optional keys are `priority`,
        `maxItemCount`, `groupIndex` and `keywordLength`. See the nvim-cmp
        documentation for more information.
      '';
    };
    snippetExpand = mkOption {
      type = with types; nullOr nonEmptyStr;
      default = null;
      example = ''
        function(args)
          luasnip.lsp_expand(args.body)
        end
      '';
      description = ''
        A Lua anonymous function for performing snippet expansion.
      '';
    };
    experimental = mkOption {
      type = with types; nullOr (types.submodule {
        options = {
          ghostText = defaultNullOrBoolOption "Display ghost text completions.";
          nativeMenu = defaultNullOrBoolOption "Use native menu.";
        };
      });
      default = null;
      description = "Experimental features. See nvim-cmp documentation for details.";
    };
    preselectItem = defaultNullOrBoolOption ''
      Whether to preselect a menu item for completion.
    '';
    formatting = mkOption {
      type = with types; nullOr (types.submodule {
        options = {
          format = mkOption {
            type = nullOr nonEmptyStr;
            default = null;
            description = ''
              A Lua anonymous function specifying formatting completions. See
              nvim-cmp documentation for details.
            '';
          };
        };
      });
      default = null;
      description = "Formatting options.";
    };
  };

  config.programs.neovim = mkIf cfg.enable {
    extraConfig = let

      dropNulls = source: filterAttrs (_: v: (! isNull v)) source;
      camelKeys = source: mapAttrs' (n: v: (nameValuePair (lua.camelToSnake n) v)) source;
      camelNonNull = source: (dropNulls (camelKeys source));
      strIfNotNull = v: s: optionalString (! isNull v) s;
      keyMappingsTable = ''
        local keyMappings = {}
      '' +
      (concatStringsSep "\n"
        (mapAttrsToList (n: v: "keyMappings['${n}'] = ${v}") cfg.keyMappings)
      ) + strIfNotNull cfg.keyMappings "\n";
      sourcesTable = let
      in ''
        local completionSources = ${lua.asLua (map camelNonNull cfg.sources)}
      '';
    in
      ''
        lua << EOF
        local cmp = require("cmp")
      '' +
      sourcesTable +
      (strIfNotNull cfg.keyMappings keyMappingsTable) +
      strIfNotNull cfg.snippetExpand ''
        local snippetExpand = ${cfg.snippetExpand}
      '' +
      strIfNotNull cfg.sorting (''
        local sortingOptions = {
      '' +
      strIfNotNull cfg.sorting.comparators "  comparators = {${concatStringsSep "," cfg.sorting.comparators}},\n" +
      strIfNotNull cfg.sorting.priorityWeight "  priority_weight = ${toString cfg.sorting.priorityWeight},\n" +
      ''
        }
      '') +
      strIfNotNull cfg.formatting (''
      '' + strIfNotNull cfg.formatting.format ''
        local formatFn = ${cfg.formatting.format}
      '') +
      strIfNotNull cfg.experimental ''
        local experimentalOpts = ${lua.asLua (camelNonNull cfg.experimental)}
      '' +
      ''
        cmp.setup {
      '' +
      "  sources = completionSources,\n" +
      strIfNotNull cfg.keyMappings "  mapping = keyMappings,\n" +
      strIfNotNull cfg.sorting "  sorting = sortingOptions,\n" +
      strIfNotNull cfg.experimental "  experimental = experimentalOpts,\n" +
      strIfNotNull cfg.snippetExpand "  snippet = { expand = snippetExpand },\n" +
      strIfNotNull cfg.preselectItem ("  preselect = cmp.PreselectMode." +
        (if cfg.preselectItem then "Item" else "None") + ",\n") +
      strIfNotNull cfg.formatting ("  formatting = {\n" +
      strIfNotNull cfg.formatting.format "    format = formatFn,\n" +
      "  }\n") +
      ''
        }
      '' +
      ''
        EOF
      '';
  };
}
