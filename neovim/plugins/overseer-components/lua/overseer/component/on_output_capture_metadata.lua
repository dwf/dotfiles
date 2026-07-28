return {
  desc = "Extract from output based on a Lua pattern into task metadata",
  -- callback is a raw function; it can't survive vim.json.encode, so this
  -- component is dropped rather than erroring when a bundle is saved.
  serializable = false,
  params = {
    key = { desc = "Metadata key to set", type = "string" },
    pattern = { desc = "Lua pattern to match against each output line", type = "string" },
    first = { desc = "First match per execution", type = "boolean", optional = true, default = true },
    callback = {
      desc = "Function(task) called after metadata is set",
      type = "opaque",
      optional = true,
    },
  },
  constructor = function(params)
    local found_match = false
    return {
      on_reset = function(self, task)
        found_match = false
        if task.metadata then
          task.metadata[params.key] = nil
        end
      end,
      on_output_lines = function(self, task, lines)
        if params.first and found_match then
          return
        end
        for _, line in ipairs(lines) do
          local match = line:match(params.pattern)
          if match then
            task.metadata = task.metadata or {}
            task.metadata[params.key] = match
            found_match = true
            if params.callback then
              params.callback(task)
            end
            if params.first then
              break
            end
          end
        end
      end,
    }
  end,
}
