{
  config.plugins.none-ls = {
    enable = true;
    lazyLoad.settings.event = "DeferredUIEnter";
    sources = {
      code_actions = {
        gitsigns.enable = true;
        statix.enable = true;
      };
      diagnostics = {
        checkmake.enable = true;
        deadnix.enable = true;
        statix.enable = true;
      };
    };
  };
}
