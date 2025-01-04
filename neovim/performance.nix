{ pkgs, ... }:
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
      ];
    };
  };
  luaLoader.enable = true;

  # I can't get standalonePlugins to solve the overseer/conform collision so
  # just patch the derivation.
  plugins.overseer.package = pkgs.vimPlugins.overseer-nvim.overrideAttrs {
    postInstall = ''
      mv $out/doc/recipes.md $out/doc/overseer-recipes.md
    '';
  };
}
