local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local events = require("luasnip.util.events")
local c = require("luasnip.extras.conditions")

-- True unless the cursor sits inside a string or comment node -- guards
-- against a trigger typed as prose (a docstring mentioning "jnp.", a "#
-- np." comment) being mistaken for real code and inserting an import.
-- Checked at cursor_col - 1, since by the time this runs the trigger text
-- (e.g. "jnp.") is already in the buffer and the cursor sits just past it;
-- querying at the cursor itself risks landing on the boundary node (e.g.
-- the string's closing quote) rather than the trigger text.
local function not_in_string_or_comment()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
  if not ok or not parser then
    return true
  end
  -- get_node() doesn't force a parse itself -- it just returns nil for any
  -- position on a tree that hasn't been parsed yet, which would silently
  -- fail this check open (permissive) rather than actually detecting
  -- string/comment context.
  parser:parse()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, math.max(cursor[2] - 1, 0)
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, col } })
  while node do
    local node_type = node:type()
    if node_type == "string" or node_type == "comment" then
      return false
    end
    node = node:parent()
  end
  return true
end

-- Typing `jnp.` (no expand key needed -- this is an autosnippet) adds
-- `import jax.numpy as jnp` at the top of the file, if it isn't already
-- there; the snippet's own body is just the trigger text again, so it's a
-- no-op text-wise beyond firing the callback. Mirrors nix.lua's
-- dot_autoimport_snippet, but as an autosnippet rather than one requiring
-- the expand key, and via python-helpers.add_import instead of
-- nix-module-args.ensure_arg.
--
-- add_import runs on the next tick (vim.schedule), not synchronously in
-- pre_expand: when the trigger is typed at the very start of the buffer's
-- first line (e.g. an empty file, cursor at (0,0)) and there's no existing
-- import block, add_import's insertion point is also (0,0) -- the same
-- spot the snippet's own extmark for re-inserting "jnp." sits at. Editing
-- there *during* pre_expand collides with that extmark before it's had a
-- chance to settle, and "jnp." ends up prepended onto the new import line
-- instead of staying on its own line below it. Deferring the edit until
-- after the snippet has finished placing its nodes avoids the collision
-- entirely.
local function dot_autoimport_snippet(name, alias)
  local trig = (alias or name) .. "."
  local desc = alias and ("Auto-import " .. name .. " as " .. alias .. ".") or ("Auto-import " .. name .. ".")
  return s(
    { trig = trig, desc = desc },
    { t(trig) },
    {
      condition = c.make_condition(not_in_string_or_comment),
      callbacks = {
        [-1] = {
          [events.pre_expand] = function()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.schedule(function()
              require("python-helpers").add_import(bufnr, { name = name, alias = alias })
            end)
          end,
        },
      },
    }
  )
end

local autosnippets = {
  dot_autoimport_snippet("jax.numpy", "jnp"),
  dot_autoimport_snippet("numpy", "np"),
  dot_autoimport_snippet("chex"),
}

return {}, autosnippets
