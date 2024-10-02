local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local events = require("luasnip.util.events")

local function py_manual_autoimport_snippet(import_statement, trigger, line_number_callback, insert_text)
  -- Manually add an import in some heuristically chosen place on first use of a trigger.
  if insert_text == nil then
    insert_text = trigger
  end
  return s(trigger, { t(insert_text) }, {
    callbacks = {
      [-1] = {

        [events.pre_expand] = function()
          -- Exactly match the import statement. There could be comments after it or something,
          -- but that's unlikely for my use cases.
          local import_match_pattern = "^" .. import_statement .. "$"
          if vim.b.py_manual_autoimport_cache == nil then
            vim.b.py_manual_autoimport_cache = {}
          end
          local cached_line_num = vim.b.py_manual_autoimport_cache[trigger]
          if cached_line_num ~= nil then
            local line = vim.api.nvim_buf_get_lines(0, cached_line_num, cached_line_num, false)[1]
            if line:match(import_match_pattern) then
              return
            end
          end
          local matches = vim.fn.matchbufline(vim.fn.bufname(0), import_match_pattern, 1, "$")
          if #matches > 0 then
            vim.b.py.manual_autoimport_cache[trigger] = matches[1].lnum
          else
            local insert_lnum = line_number_callback()
            if insert_lnum ~= nil then
              vim.api.nvim_buf_set_lines(0, insert_lnum, insert_lnum, false, { import_statement })
              vim.b.py_manual_autoimport_cache[trigger] = insert_lnum
            end
          end
        end,
      },
    },
  })
end

return {}, {
  -- py_manual_autoimport_snippet("import jax.numpy as jnp", "jnp.", function()
  --   local matches = vim.fn.matchbufline(vim.fn.bufname(0), "^import \\(jax\\|numpy as np\\)$", 1, "$")
  --   if matches[1] ~= nil and matches[1].lnum ~= nil then
  --     local lnum = matches[1].lnum
  --     if matches[1].text:match(".*numpy") then
  --       lnum = lnum - 1
  --     end
  --     return lnum
  --   end
  -- end),
}
