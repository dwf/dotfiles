local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

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
  s(
    { trig = "snip", desc = "Basic luasnip snippet" },
    fmt(
      [[
      s({{ trig = "{}", desc = "{}" }}, {{
        {}
      }}){}
      ]],
      {
        i(1, "trigger"),
        i(2, "description"),
        i(3, "-- nodes"),
        i(0),
      }
    )
  ),
  s(
    { trig = "fsnip", desc = "Formatted luasnip snippet" },
    fmt(
      [=[
        s(
          {{ trig = "{}", desc = "{}" }},
          fmt(
            [[
            {}
            ]],
            {{
              {}
            }}
          )
        ){}
      ]=],
      {
        i(1, "trigger"),
        i(2, "description"),
        i(3, "-- text"),
        i(4, "-- nodes"),
        i(0),
      }
    )
  ),
}, {}
