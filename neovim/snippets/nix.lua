local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local ce = require("luasnip.extras.conditions.expand")

local function makeImportSnippet()
  return fmt(
    [[
      imports = [
        {}
      ];{}
    ]],
    {
      i(1, "# imports go here"),
      i(0),
    }
  )
end

return {
  s(
    { trig = "_skel", desc = "Basic module template", hidden = true },
    fmt(
      [[
      {{ {}... }}:
      {{
        {}
      }}
      ]],
      {
        i(1),
        i(0),
      }
    )
  ),
  s({ trig = "imp", desc = "imports = [ ... ];" }, makeImportSnippet()),
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
}, {
  s("imports ", makeImportSnippet(), {
    condition = ce.line_begin * ce.line_end,
  }),
}
