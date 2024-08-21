local models = {
  ["codegemma:2b-code"] = {
    model = "codegemma:2b-code",
    fim = {
      prefix = "<|fim_prefix|>",
      middle = "<|fim_middle|>",
      suffix = "<|fim_suffix|>",
    },
    tokens_to_clear = {
      "<|file_separator|>",
    },
    tokenizer = {
      repository = "google/codegemma-2b",
    },
    context_window = 8192,
  },
  ["knoopx/refact:1.6b-q8_0"] = {
    model = "knoopx/refact:1.6b-q8_0",
    fim = {
      prefix = "<fim_prefix>",
      middle = "<fim_middle>",
      suffix = "<fim_suffix>",
    },
    tokens_to_clear = {
      "<|endoftext|>",
    },
    tokenizer = {
      repository = "oblivious/Refact-1.6B-fim-GGUF",
    },
    context_window = 4096,
  },
  ["starcoder2:3b-q4_K_M"] = {
    model = "starcoder2:3b-q4_K_M",
    fim = {
      prefix = "<fim_prefix>",
      middle = "<fim_middle>",
      suffix = "<fim_suffix>",
    },
    tokens_to_clear = {
      "<|endoftext|>",
    },
    tokenizer = {
      repository = "bigcode/starcoder2-3b",
    },
    context_window = 16384,
  },
  ["codellama:7b-code-q4_K_M"] = {
    model = "codellama:7b-code-q4_K_M",
    fim = {
      prefix = "<PRE> ",
      middle = " <MID>",
      suffix = " <SUF>",
    },
    tokens_to_clear = {
      "<EOT>",
    },
    tokenizer = {
      repository = "codellama/CodeLlama-7b-hf",
    },
    context_window = 16384,
  },
  ["deepseek-coder:1.3b-base"] = {
    model = "deepseek-coder:1.3b-base",
    fim = {
      prefix = "<｜fim▁begin｜>",
      middle = "<｜fim▁hole｜>",
      suffix = "<｜fim▁end｜>",
    },
    tokens_to_clear = {
      "<｜end▁of▁sentence｜>",
    },
    tokenizer = {
      repository = "deepseek-ai/deepseek-vl-1.3b-base",
    },
    context_window = 16384,
  },
}

local servers = { "localhost", "wheeljack" }

local model_names = {}
for key, _ in pairs(models) do
  model_names[#model_names + 1] = key
end

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

local update_llm_config = function(model_name)
  local llm_cfg = require("llm.config")
  local model_cfg = models[model_name]
  llm_cfg.config = vim.tbl_deep_extend("force", llm_cfg.config, model_cfg)
  vim.notify("Selected " .. model_name)
end

make_picker(
  "Model to use for completion:",
  model_names,
  update_llm_config,
  { layout_strategy = "vertical", layout_config = { height = 15, width = 0.2 } }
)

-- make_picker(
--   "Ollama server to use:",
--   servers,
--   update_llm_server,
--   { layout_strategy = "vertical", layout_config = { height = 8, width = 0.2 } }
-- )
