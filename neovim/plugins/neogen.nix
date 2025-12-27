{ ... }:
{
  config = {
    plugins.neogen = {
      enable = true;
      keymaps.generate = "<Leader>ga";
      settings.snippet_engine = "luasnip";
    };
    files."ftplugin/python.lua".extraConfigLuaPost = # lua
      ''
        -- Use two spaces rather than four when generating docstring stubs if sw=2
        -- (under the pretty reasonable assumption that we don't have different
        -- Python buffers with different shiftwidth values)
        local template = require("neogen").configuration.languages.python.template.google_docstrings
        for key, rule in pairs(template) do
          if string.sub(rule[2], 1, 4) == "    " then
            template[key][2] = string.sub(rule[2], 3, string.len(rule[2]))
          end
        end
      '';
  };
}
