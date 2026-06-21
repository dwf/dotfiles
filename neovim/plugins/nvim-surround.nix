{ pkgs, lib, ... }:
let
  DeferredUIEnter = "DeferredUIEnter";
in
{
  config = {
    plugins.nvim-surround = {
      enable = true;
      lazyLoad.settings.event = [ DeferredUIEnter ];
    };
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "nvim-surround-wk";
        src = pkgs.fetchFromGitHub {
          owner = "gregorias";
          repo = "nvim-surround-wk";
          rev = "d8f4058cab1f0a4805e0e9f7e1415607681265f6";
          sha256 = "sha256-41RttsqCI9y3ID7h8tmlcRmNtA9WNjyKp9R7ISLghjQ=";
        };
        version = "2026-06-21";
      })
    ];

    plugins.lz-n.plugins = [
      {
        __unkeyed-1 = "nvim-surround-wk";
        event = [ DeferredUIEnter ];
      }
    ];
  };
}
