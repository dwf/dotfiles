return {
  desc = "Extract from output based on Lua patterns into task metadata",
  -- per-key callbacks are raw functions; they can't survive vim.json.encode,
  -- so this component is dropped rather than erroring when a bundle is saved.
  serializable = false,
  params = {
    -- Table of metadata key -> { pattern = "...", first = bool?, callback =
    -- fun?(task) }. Not a structured `type`, since overseer's param schema
    -- has no notion of a table keyed by arbitrary strings, and each value's
    -- `callback` is itself a raw function; "opaque" matches how this
    -- component already treats callbacks as unvalidated raw values.
    keys = {
      desc = 'Table of metadata key -> { pattern, first?, callback? } to extract from output',
      type = "opaque",
    },
  },
  constructor = function(params)
    local found_match = {}
    return {
      on_reset = function(self, task)
        found_match = {}
        if task.metadata then
          for key in pairs(params.keys) do
            task.metadata[key] = nil
          end
        end
      end,
      on_output_lines = function(self, task, lines)
        for key, spec in pairs(params.keys) do
          local first = spec.first
          if first == nil then
            first = true
          end
          if not (first and found_match[key]) then
            for _, line in ipairs(lines) do
              local match = line:match(spec.pattern)
              if match then
                task.metadata = task.metadata or {}
                task.metadata[key] = match
                found_match[key] = true
                if spec.callback then
                  spec.callback(task)
                end
                if first then
                  break
                end
              end
            end
          end
        end
      end,
    }
  end,
}
