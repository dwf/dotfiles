{
  config.plugins.treesitter = {
    enable = true;
    # settings.incremental_selection in a future nixvim
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
}
