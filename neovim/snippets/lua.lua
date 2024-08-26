local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s({ trig = "req", desc = "require(...)" }, {
    t('require("'),
    i(1, "module"),
    t('")'),
    i(0),
  }),
  s({ trig = "reql", desc = "local mod = require(...)" }, {
    t("local "),
    i(1, "alias"),
    t(' = require("'),
    i(2, "module"),
    t('")'),
    i(0),
  }),
}, {}
