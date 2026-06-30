{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.plugins.treesitter = {
    enable = true;
    lazyLoad.settings.event = "DeferredUIEnter";
    highlight = {
      enable = true;
      disable = [
        "tmux" # the treesitter grammar has a bug with 'set -g status' [no value]
      ];
    };
    # settings.incremental_selection in a future nixvim
    settings = {
      incrementalSelection = {
        enable = true;
        keymaps = {
          # snake-case in a future nixvim
          nodeIncremental = "=";
          nodeDecremental = "-";
          scopeIncremental = "+";
        };
      };
      nixvimInjections = true;
    };

    # Same grammar selection as the default decorator, but flatten the combined
    # grammars derivation into ONE store path with the Lua instead of leaving it
    # as a separate rtp entry.
    packageDecorator = lib.mkForce (
      pkg:
      pkgs.symlinkJoin {
        name = "nvim-treesitter-with-parsers";
        paths = [ pkg ] ++ (pkg.withPlugins (_: config.plugins.treesitter.grammarPackages)).dependencies;
      }
    );
  };
}
