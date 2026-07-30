return {
  desc = "Inject callback-provided args into task.cmd, adding a separator first if not already present",
  -- callback is a raw function; it can't survive vim.json.encode, so this
  -- component is dropped rather than erroring when a bundle is saved.
  serializable = false,
  params = {
    callback = { desc = "Function(task): string or list of strings to inject", type = "opaque" },
    separator = {
      desc = "Separator to ensure precedes the injected args",
      type = "string",
      optional = true,
      default = "--",
    },
  },
  constructor = function(params)
    -- overseer.Task.new() calls both add_components() (which calls on_init
    -- directly, since task.id is already assigned by that point) and then
    -- dispatch("on_init") (which calls on_init on every component again) -
    -- on_init genuinely fires twice per task, so injection must be
    -- idempotent or the args (not just the separator, which is already
    -- deduped by the has_sep/tbl_contains checks below) get doubled.
    local injected = false
    return {
      on_init = function(_, task)
        if injected then
          return
        end
        injected = true
        local extra = params.callback(task)
        if type(extra) == "string" then
          extra = { extra }
        end
        local cmd = task.cmd
        if type(cmd) == "string" then
          local has_sep = false
          for word in cmd:gmatch("%S+") do
            if word == params.separator then
              has_sep = true
              break
            end
          end
          local parts = { cmd }
          if not has_sep then
            table.insert(parts, params.separator)
          end
          vim.list_extend(parts, extra)
          task.cmd = table.concat(parts, " ")
        else
          if not vim.tbl_contains(cmd, params.separator) then
            table.insert(cmd, params.separator)
          end
          vim.list_extend(cmd, extra)
        end
      end,
    }
  end,
}
