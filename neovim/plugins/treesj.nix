{ helpers, ... }:
{
  config = {
    plugins.treesj = {
      enable = true;
      lazyLoad.settings.event = "DeferredUIEnter";
      settings.use_default_keymaps = false;
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
