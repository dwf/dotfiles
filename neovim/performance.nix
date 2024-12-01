{
    performance = {
    byteCompileLua = {
      enable = true;
      nvimRuntime = true;
      configs = true;
      plugins = true;
    };
    combinePlugins = {
      enable = true;
      standalonePlugins = [
        # Collisions
        "nvim-treesitter"
        "nvim-treesitter-textobjects"
        "vimplugin-treesitter-grammar-nix"
        "overseer-nvim"
      ];
    };
  };
  luaLoader.enable = true;
}
