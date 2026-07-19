local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local events = require("luasnip.util.events")

local function ensure_arg_callback(name)
  return {
    callbacks = {
      [-1] = {
        [events.pre_expand] = function()
          require("nix-module-args").ensure_arg(0, name)
        end,
      },
    },
  }
end

-- Typing `pkgs.` (then the expand key) auto-adds `pkgs` as a module
-- parameter if it isn't one already; the snippet's own body is just the
-- trigger text again, so it's a no-op text-wise beyond firing the callback.
local function dot_autoimport_snippet(name)
  local dotted = name .. "."
  return s(dotted, { t(dotted) }, ensure_arg_callback(name))
end

-- Same idea for `with pkgs;`.
local function with_autoimport_snippet(name)
  local trig = "with " .. name .. ";"
  return s(trig, { t(trig) }, ensure_arg_callback(name))
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
    ),
    {
      callbacks = {
        [-1] = {
          [events.leave] = function()
            require("nix-module-args").prune_empty_arg(0)
          end,
        },
      },
    }
  ),
  dot_autoimport_snippet("pkgs"),
  dot_autoimport_snippet("lib"),
  with_autoimport_snippet("pkgs"),
  with_autoimport_snippet("lib"),
}
