{ pkgs, lib, ... }:
let
  helpers = lib.nixvim;

  # nvim-surround's own plugin/nvim-surround.lua registers these default
  # global keymaps (ys/yss/yS/ySS/ds/cs/cS in normal, S/gS in visual, <C-g>s/S
  # in insert) itself when it loads - they don't exist at all beforehand, so
  # bare (no explicit action) lz.n key triggers here load the plugin on first
  # press and then replay the same keys, letting the real mappings take over.
  surroundKeys = [
    { __unkeyed-1 = "ys"; }
    { __unkeyed-1 = "yss"; }
    { __unkeyed-1 = "yS"; }
    { __unkeyed-1 = "ySS"; }
    { __unkeyed-1 = "ds"; }
    { __unkeyed-1 = "cs"; }
    { __unkeyed-1 = "cS"; }
    {
      __unkeyed-1 = "S";
      mode = "x";
    }
    {
      __unkeyed-1 = "gS";
      mode = "x";
    }
    {
      __unkeyed-1 = "<C-g>s";
      mode = "i";
    }
    {
      __unkeyed-1 = "<C-g>S";
      mode = "i";
    }
  ];
in
{
  config = {
    plugins.nvim-surround = {
      enable = true;
      lazyLoad.settings.keys = surroundKeys;
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
        keys = surroundKeys;
        # nvim-surround-wk's setup() monkey-patches nvim-surround.input
        # directly (require("nvim-surround.input").get_char = ...) and also
        # requires which-key, so both need to already be loaded regardless of
        # which of nvim-surround-wk's own triggers fired first.
        before = helpers.mkRaw ''
          function()
            require('lz.n').trigger_load('nvim-surround')
            require('lz.n').trigger_load('which-key.nvim')
          end
        '';
        # Nothing else in this config calls setup() - the README's lazy.nvim
        # install snippet relies on lazy.nvim's `config = true` shorthand for
        # this, which has no lz.n equivalent, so it has to be done here.
        after = helpers.mkRaw ''
          function()
            require('nvim-surround-wk').setup()
          end
        '';
      }
    ];
  };
}
