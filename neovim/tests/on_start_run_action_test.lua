-- Unit tests for
-- neovim/plugins/overseer-components/lua/overseer/component/on_start_run_action.lua
--
-- overseer.run_action is stubbed via package.loaded before the component is
-- first required, so this needs no real task runtime or network access.
--
--   nvim --headless -c "lua dofile('neovim/tests/on_start_run_action_test.lua')"
--
-- Exits via :cquit (nonzero) if any test fails.

local calls = {}
package.loaded["overseer"] = {
  run_action = function(task, name)
    table.insert(calls, { task = task, name = name })
  end,
}

local component = require("overseer.component.on_start_run_action")

local tests = {}
local function test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

local function assert_eq(actual, expected, context)
  if actual ~= expected then
    error(
      string.format(
        "%s:\n  expected: %s\n  actual:   %s",
        context or "assertion failed",
        vim.inspect(expected),
        vim.inspect(actual)
      )
    )
  end
end

test("runs the action when the condition returns true", function()
  calls = {}
  local task = { name = "build" }
  local instance = component.constructor({
    action = "restart",
    condition = function()
      return true
    end,
  })
  instance.on_start(instance, task)
  assert_eq(#calls, 1, "expected exactly one run_action call")
  assert_eq(calls[1].task, task, "run_action should be called with the task")
  assert_eq(calls[1].name, "restart", "run_action should be called with the configured action name")
end)

test("does not run the action when the condition returns false", function()
  calls = {}
  local task = { name = "build" }
  local instance = component.constructor({
    action = "restart",
    condition = function()
      return false
    end,
  })
  instance.on_start(instance, task)
  assert_eq(#calls, 0, "run_action should not be called when the condition is false")
end)

test("the condition function receives the task", function()
  calls = {}
  local task = { name = "build", metadata = { version = "1.2.3" } }
  local seen_task = nil
  local instance = component.constructor({
    action = "restart",
    condition = function(t)
      seen_task = t
      return t.metadata and t.metadata.version == "1.2.3"
    end,
  })
  instance.on_start(instance, task)
  assert_eq(seen_task, task, "condition should be called with the task")
  assert_eq(#calls, 1, "condition inspecting task.metadata should be able to gate the action")
end)

local failures = {}
for _, t in ipairs(tests) do
  local ok, err = pcall(t.fn)
  if ok then
    print("ok - " .. t.name)
  else
    print("FAIL - " .. t.name)
    print("  " .. tostring(err):gsub("\n", "\n  "))
    table.insert(failures, t.name)
  end
end

print(string.format("\n%d passed, %d failed", #tests - #failures, #failures))

if #failures > 0 then
  vim.cmd("cquit")
else
  vim.cmd("quit")
end
