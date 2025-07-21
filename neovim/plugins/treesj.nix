{ helpers, pkgs, ... }:
{
  config = {
    plugins.treesj = {
      enable = true;
      lazyLoad.settings.event = "DeferredUIEnter";
      settings = {
        use_default_keymaps = false;
        langs.starlark.argument_list = helpers.mkRaw ''
          require('treesj.langs.utils').set_preset_for_args({
            split = { last_separator = true }
          })
        '';
      };
    };
    keymaps =
      [
        {
          key = "<Leader>S";
          action = helpers.mkRaw ''
            function()
              require('lz.n').trigger_load('treesj')
              require('treesj').toggle({ split = { recursive = true } })
            end
          '';
          mode = [
            "n"
            "v"
          ];
          options = {
            silent = true;
            desc = "Toggle split/join (recursive)";
          };
        }
      ]
      ++ (map
        (key: {
          inherit key;
          action = helpers.mkRaw ''
            function()
              require('lz.n').trigger_load('treesj')
              require('treesj').toggle()
            end
          '';
          mode = [
            "n"
            "v"
          ];
          options = {
            silent = true;
            desc = "Toggle split/join";
          };
        })
        [
          "gS"
          "<Leader>s"
        ]
      );
  };
}
