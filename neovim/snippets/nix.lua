local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local events = require("luasnip.util.events")

-- Deferred (vim.schedule), not run synchronously in pre_expand: these are
-- autosnippets (expand on typing, no expand key), same mechanism as
-- python-helpers' jnp. snippet -- and for the same reason that one needs
-- deferring, this does too: ensure_arg's insertion point can coincide
-- with the spot the snippet's own extmark for re-inserting the trigger
-- text sits at (e.g. typing `pkgs.` at the very start of a headerless
-- file), and editing there synchronously, before that extmark settles,
-- garbles the two together. Deferring until after the snippet has
-- finished placing its nodes avoids the collision.
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

-- Typing `pkgs.` auto-adds `pkgs` as a module parameter if it isn't one
-- already; the snippet's own body is just the trigger text again, so it's
-- a no-op text-wise beyond firing the callback.
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
}, {
  dot_autoimport_snippet("pkgs"),
  dot_autoimport_snippet("lib"),
  dot_autoimport_snippet("config"),
  with_autoimport_snippet("pkgs"),
  with_autoimport_snippet("lib"),
}
