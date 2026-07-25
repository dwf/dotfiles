{ ... }:
{
  config = {
    plugins.neogen = {
      enable = true;
      lazyLoad.settings.cmd = [ "Neogen" ];
      keymaps.generate = "<Leader>ga";
      settings.snippet_engine = "luasnip";
    };
    files."ftplugin/python.lua".extraConfigLuaPost = # lua
      ''
        -- Use two spaces rather than four when generating docstring stubs if sw=2
        -- (under the pretty reasonable assumption that we don't have different
        -- Python buffers with different shiftwidth values)
        --
        -- neogen is now lazy-loaded (see plugins.neogen.lazyLoad above), so
        -- force it to load here rather than require()-ing it directly -
        -- otherwise this runs on every Python buffer, before neogen has ever
        -- been packadd-ed, and require() fails with "module not found".
        require('lz.n').trigger_load('neogen')
        local template = require("neogen").configuration.languages.python.template.google_docstrings
        for key, rule in pairs(template) do
          if string.sub(rule[2], 1, 4) == "    " then
            template[key][2] = string.sub(rule[2], 3, string.len(rule[2]))
          end
        end
      '';
  };
}
