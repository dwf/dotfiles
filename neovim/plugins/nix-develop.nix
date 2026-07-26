{
  config.plugins.nix-develop = {
    enable = true;
    # Pure on-demand env loader - nothing else depends on it being loaded
    # early, so gate it on its own commands (same idiom as
    # codediff/diffview in default.nix).
    lazyLoad.settings.cmd = [
      "NixDevelop"
      "NixShell"
      "DevenvShell"
      "RiffShell"
    ];
  };
}
