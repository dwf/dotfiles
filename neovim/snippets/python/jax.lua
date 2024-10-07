local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local events = require("luasnip.util.events")
local helpers = require("treesitter-helpers.python")

local function autoimport_snippet(import_spec, opts)
  if opts == nil then
    opts = {}
  end
  local imported = import_spec.name
  if import_spec.alias ~= nil then
    imported = import_spec.alias
  end
  local insert_text = imported .. "."
  if opts.trigger == nil then
    opts.trigger = insert_text
  end
  return s(opts.trigger, { t(insert_text) }, {
    callbacks = {
      [-1] = {
        [events.pre_expand] = function()
          helpers.maybe_add_import(0, import_spec, opts)
        end,
      },
    },
  })
end

return {}, {
  autoimport_snippet({ name = "jax.numpy", alias = "jnp" }, {
    placement = {
      { "after", { name = "jax" } },
      { "before", { name = "numpy", alias = "np" } },
    },
  }),
}
