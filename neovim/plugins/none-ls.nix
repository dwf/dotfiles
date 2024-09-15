{
  config.plugins.none-ls = {
    enable = true;
    sources = {
      code_actions = {
        gitsigns.enable = true;
        statix.enable = true;
      };
      diagnostics = {
        checkmake.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        trail_space.enable = true;
      };
    };
  };
}
