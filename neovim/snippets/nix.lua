local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local ce = require("luasnip.extras.conditions.expand")
local events = require("luasnip.util.events")

local pkgs_import_callback = {
  callbacks = {
    [-1] = {
      [events.pre_expand] = function()
        require("treesitter-helpers.nix").maybe_add_module_import(0, "pkgs")
      end,
    },
  },
}

local function make_import_snippet()
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
  s({ trig = "imp", desc = "imports = [ ... ];" }, make_import_snippet()),
  s(
    {
      trig = "gh",
      desc = "pkgs.fetchFromGitHub { ... }",
    },
    fmt(
      [[
    {}fetchFromGitHub {{
      owner = "{}";
      repo = "{}";
      rev = "{}";
      sha256 = "";
    }}{}
  ]],
      {
        i(1, "pkgs."),
        i(2, "user"),
        i(3, "repository"),
        i(4, "hash"),
        i(0),
      }
    ),
    pkgs_import_callback
  ),
  s(
    { trig = "vimpl", desc = "buildVimPlugin { ... }" },
    fmt(
      [[
        {}buildVimPlugin {{
          pname = "{}";
          src = {};
        }}{}
      ]],
      {
        i(1, "pkgs.vimUtils."),
        i(2, ""),
        i(3, "{}"),
        i(0),
      }
    ),
    pkgs_import_callback
  ),
}, {
  s("imports ", make_import_snippet(), {
    condition = ce.line_begin * ce.line_end,
  }),
}
