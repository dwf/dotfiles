{
  config.plugins.lualine = {
    enable = true;
    lazyLoad.settings.event = "DeferredUIEnter";
    settings.sections = {
      lualine_x = [
        "encoding"
        "fileformat"
        "filetype"
      ];
    };
  };
}
