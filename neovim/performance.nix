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
        # Ships root-level assets (VERSION, libvscode_diff.so, libgomp.so.1)
        # that the combined plugin pack drops, breaking runtime lib loading.
        "codediff.nvim"
        # sidekick.nvim also needs standalone treatment; see ./plugins/sidekick.nix.
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
