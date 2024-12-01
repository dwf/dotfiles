{
  config.plugins.treesitter = {
    enable = true;
    disabledLanguages = [
      "tmux" # the treesitter grammar has a bug with 'set -g status' [no value]
    ];
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
  };
}
