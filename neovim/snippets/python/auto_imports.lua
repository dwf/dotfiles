local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local events = require("luasnip.util.events")

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
local autosnippets = {
  s(
    { trig = "jnp.", desc = "Auto-import jax.numpy as jnp." },
    { t("jnp.") },
    {
      callbacks = {
        [-1] = {
          [events.pre_expand] = function()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.schedule(function()
              require("python-helpers").add_import(bufnr, { name = "jax.numpy", alias = "jnp" })
            end)
          end,
        },
      },
    }
  ),
}

return {}, autosnippets
