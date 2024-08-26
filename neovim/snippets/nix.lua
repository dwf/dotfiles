local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

return {
  s(
    { trig = "gh", desc = "pkgs.fetchFromGitHub { ... }" },
    fmt(
      [[
    {}fetchFromGitHub {{
      owner = "{}";
      repo = "{}";
      rev = "{}";
      sha256 = "";
    }};{}
  ]],
      {
        i(1, "pkgs."),
        i(2, "user"),
        i(3, "repository"),
        i(4, "hash"),
        i(0),
      }
    )
  ),
}, {}
