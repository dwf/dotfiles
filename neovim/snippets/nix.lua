local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local ce = require("luasnip.extras.conditions.expand")
local events = require("luasnip.util.events")

local function import_callback(name)
  return {
    callbacks = {
      [-1] = {
        [events.pre_expand] = function()
          require("treesitter-helpers.nix").maybe_add_module_import(0, name)
        end,
      },
    },
  }
end

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

local function make_auto_import_snippet(name)
  local dotted = name .. "."
  return s(dotted, { t(dotted) }, import_callback(name))
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
    import_callback("pkgs")
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
    import_callback("pkgs")
  ),
}, {
  s("imports ", make_import_snippet(), {
    condition = ce.line_begin * ce.line_end,
  }),
  make_auto_import_snippet("helpers"),
  make_auto_import_snippet("pkgs"),
  make_auto_import_snippet("lib"),
}
