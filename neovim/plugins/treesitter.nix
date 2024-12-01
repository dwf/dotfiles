{
  config.plugins.treesitter = {
    enable = true;
    # settings.incremental_selection in a future nixvim
    settings = {
      highlight = {
        enable = true;
        disable = [
          "tmux" # the treesitter grammar has a bug with 'set -g status' [no value]
        ];
      };
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
