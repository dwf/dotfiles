{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    plugins.hardtime = {
      enable = true;
      lazyLoad.settings = {
        cmd = "Hardtime";
        keys = [
          {
            __unkeyed-1 = "<leader>h";
            __unkeyed-2 = helpers.mkRaw ''
              function()
                local hardtime = require('hardtime')
                if hardtime.is_plugin_enabled then
                  vim.notify(
                    "Disabling hardtime.nvim",
                    vim.log.levels.INFO,
                    { title = "hardtime" }
                  )
                  hardtime.disable {}
                else
                  vim.notify(
                    "Enabling hardtime.nvim",
                    vim.log.levels.INFO,
                    { title = "hardtime" }
                  )
                  hardtime.enable {}
                end
              end
            '';
            desc = "Toggle hardtime.nvim";
          }
        ];
      };
    };
  };
}
