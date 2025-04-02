{
  config.plugins.lazydev = {
    enable = true;
    lazyLoad.settings.event = [
      "BufNewFile *.lua"
      "BufRead *.lua"
    ];
  };
}
