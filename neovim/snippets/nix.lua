local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local events = require("luasnip.util.events")

-- Deferred to the next tick (vim.schedule), not run synchronously in
-- pre_expand: when the trigger is typed at the very start of the buffer's
-- first line (e.g. a headerless file, cursor at (0,0)) and there's no
-- function header yet, ensure_arg's insertion point is also (0,0) -- the
-- same spot the snippet's own extmark for re-inserting the trigger text
-- sits at. Editing there synchronously collides with that extmark before
-- it settles, and the trigger text ends up prepended onto the new header
-- line instead of staying on its own line below it (see python-helpers'
-- add_import/auto_imports.lua for the same bug, hit and fixed there
-- first). Deferring until after the snippet has finished placing its
-- nodes avoids the collision.
local function ensure_arg_callback(name)
  return {
    callbacks = {
      [-1] = {
        [events.pre_expand] = function()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.schedule(function()
            require("nix-module-args").ensure_arg(bufnr, name)
          end)
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
          -- Deferred (vim.schedule), not run synchronously: `leave` can
          -- fire from a CursorMoved-driven auto-exit (cursor wanders out
          -- of the snippet's region while it's still active), and editing
          -- text directly from inside that handler raises "Not allowed to
          -- change text or change window" (E565, textlock). Same fix as
          -- ensure_arg_callback above, different trigger for hitting it.
          [events.leave] = function()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.schedule(function()
              require("nix-module-args").prune_empty_arg(bufnr)
            end)
          end,
        },
      },
    }
  ),
  dot_autoimport_snippet("pkgs"),
  dot_autoimport_snippet("lib"),
  dot_autoimport_snippet("config"),
  with_autoimport_snippet("pkgs"),
  with_autoimport_snippet("lib"),
}
