{
  config.plugins.trim = {
    enable = true;
    lazyLoad.settings.event = "DeferredUIEnter";
    settings = {
      ft_blocklist = [
        "diff"
        "hgcommit"
        "gitcommit"
      ];
      highlight = true;
    };
  };
}
