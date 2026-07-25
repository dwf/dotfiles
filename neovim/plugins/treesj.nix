{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    plugins.treesj = {
      enable = true;
      lazyLoad.settings = {
        keys = [
          {
            __unkeyed-1 = "<Leader>S";
            __unkeyed-2 = helpers.mkRaw ''
              function()
                require('treesj').toggle({ split = { recursive = true } })
              end
            '';
            mode = [
              "n"
              "v"
            ];
            silent = true;
            desc = "Toggle split/join (recursive)";
          }
        ]
        ++ (map
          (key: {
            __unkeyed-1 = key;
            __unkeyed-2 = helpers.mkRaw ''
              function()
                require('treesj').toggle()
              end
            '';
            mode = [
              "n"
              "v"
            ];
            silent = true;
            desc = "Toggle split/join";
          })
          [
            "gS"
            "<Leader>s"
          ]
        );
      };
      settings = {
        use_default_keymaps = false;
        langs = lib.genAttrs [ "python" "starlark" ] (_: {
          argument_list = lib.mkDefault (
            helpers.mkRaw ''
              require('treesj.langs.utils').set_preset_for_args({
                split = { last_separator = true }
              })
            ''
          );
        });
      };
    };
  };
}
