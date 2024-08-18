local servers = { "localhost", "wheeljack" }

local make_picker = function(title, choices, callback, opts)
  require("telescope.pickers")
    .new(opts or {}, {
      prompt_title = title,
      finder = require("telescope.finders").new_table({
        results = choices,
      }),
      sorter = require("telescope.config").values.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        require("telescope.actions").select_default:replace(function()
          require("telescope.actions").close(prompt_bufnr)
          local selection = require("telescope.actions.state").get_selected_entry()
          callback(selection[1])
        end)
        return true
      end,
    })
    :find()
end

local update_llm_server = function(host)
  require("llm.config").config.url = "http://" .. host .. ":14434/api/generate"
  vim.notify("Selected " .. host)
end

-- make_picker(
--   "Ollama server to use:",
--   servers,
--   update_llm_server,
--   { layout_strategy = "vertical", layout_config = { height = 8, width = 0.2 } }
-- )
