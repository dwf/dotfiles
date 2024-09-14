{ pkgs, ... }:
{
  files."ftplugin/lua.lua" = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "lazydev-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "folke";
          repo = "lazydev.nvim";
          rev = "v1.8.0";
          sha256 = "sha256-D5gP2rVPYoWc8hslTrH7Z90cE7XEu+tfkD6FZzY/iPk=";
        };
        version = "2024-09-14";
      })
    ];
    extraConfigLua = # lua
      ''
        require('lazydev').setup {}
      '';
  };
}
