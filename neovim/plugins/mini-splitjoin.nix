{ helpers, ... }:
{
  config = {
    autoCmd = [
      {
        event = "BufEnter";
        pattern = "*.py";
        callback = helpers.mkRaw ''
          function()
            require('lz.n').trigger_load('mini.nvim')
            local msj = require("mini.splitjoin")
            vim.b.minisplitjoin_config = {
              split = {
                hooks_post = { msj.gen_hook.add_trailing_separator() },
              },
              join = {
                hooks_post = { msj.gen_hook.del_trailing_separator() },
              },
            }
          end
        '';
      }
    ];
    plugins.mini = {
      enable = true;
      modules.splitjoin = { };
      lazyLoad.settings.event = "DeferredUIEnter";
    };
  };
}
