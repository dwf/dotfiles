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
local autosnippets = {
  s(
    { trig = "jnp.", desc = "Auto-import jax.numpy as jnp." },
    { t("jnp.") },
    {
      callbacks = {
        [-1] = {
          [events.pre_expand] = function()
            require("python-helpers").add_import(0, { name = "jax.numpy", alias = "jnp" })
          end,
        },
      },
    }
  ),
}

return {}, autosnippets
