return {
  desc = "Run a task action on task start if a condition is met",
  -- condition is a raw function; it can't survive vim.json.encode, so this
  -- component is dropped rather than erroring when a bundle is saved.
  serializable = false,
  params = {
    action = { desc = "Name of the task action to run (see :OverseerTaskAction)", type = "string" },
    condition = { desc = "Function(task): boolean; action only runs when this returns true", type = "opaque" },
  },
  constructor = function(params)
    return {
      on_start = function(_, task)
        if params.condition(task) then
          require("overseer").run_action(task, params.action)
        end
      end,
    }
  end,
}
