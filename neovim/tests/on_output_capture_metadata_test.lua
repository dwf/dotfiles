-- Unit tests for
-- neovim/plugins/overseer-components/lua/overseer/component/on_output_capture_metadata.lua
-- No overseer task runtime is needed: constructor(params) is called directly
-- and on_reset/on_output_lines are driven against a fake `task` table.
--
--   nvim --headless -c "lua dofile('neovim/tests/on_output_capture_metadata_test.lua')"
--
-- Exits via :cquit (nonzero) if any test fails.

local component = require("overseer.component.on_output_capture_metadata")

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

local function new_task()
  return {}
end

test("first = true stops updating metadata after the first match, even across calls", function()
  local instance = component.constructor({ key = "version", pattern = "v(%d+%.%d+%.%d+)", first = true })
  local task = new_task()
  instance.on_output_lines(instance, task, { "building...", "release v1.2.3 ready" })
  assert_eq(task.metadata.version, "1.2.3", "first match should be captured")
  instance.on_output_lines(instance, task, { "release v9.9.9 ready" })
  assert_eq(task.metadata.version, "1.2.3", "later matches should be ignored once first = true has matched")
end)

test("first = true stops scanning the rest of the same batch once matched", function()
  local instance = component.constructor({ key = "version", pattern = "v(%d+%.%d+%.%d+)", first = true })
  local task = new_task()
  instance.on_output_lines(instance, task, { "v1.0.0", "v2.0.0", "v3.0.0" })
  assert_eq(task.metadata.version, "1.0.0", "should stop at the first match in the batch")
end)

test("first = false keeps updating metadata on every subsequent match", function()
  local instance = component.constructor({ key = "version", pattern = "v(%d+%.%d+%.%d+)", first = false })
  local task = new_task()
  instance.on_output_lines(instance, task, { "v1.0.0", "v2.0.0" })
  assert_eq(task.metadata.version, "2.0.0", "metadata should reflect the last match in the batch")
  instance.on_output_lines(instance, task, { "v3.0.0" })
  assert_eq(task.metadata.version, "3.0.0", "metadata should keep updating on later calls")
end)

test("different key/pattern pairs are independent", function()
  local build_instance = component.constructor({ key = "build_number", pattern = "Build #(%d+)", first = true })
  local task = new_task()
  build_instance.on_output_lines(build_instance, task, { "Starting", "Build #42 complete" })
  assert_eq(task.metadata.build_number, "42", "build_number should be captured from its own pattern")

  local branch_instance = component.constructor({ key = "branch", pattern = "^On branch (%S+)", first = true })
  branch_instance.on_output_lines(branch_instance, task, { "On branch main", "nothing to commit" })
  assert_eq(task.metadata.branch, "main", "branch should be captured from its own pattern")
  assert_eq(task.metadata.build_number, "42", "capturing a second key should not disturb the first")
end)

test("on_reset clears the captured metadata key and allows re-matching", function()
  local instance = component.constructor({ key = "version", pattern = "v(%d+%.%d+%.%d+)", first = true })
  local task = new_task()
  instance.on_output_lines(instance, task, { "v1.0.0" })
  assert_eq(task.metadata.version, "1.0.0", "sanity check: first match captured")

  instance.on_reset(instance, task)
  assert_eq(task.metadata.version, nil, "on_reset should clear the metadata key")

  instance.on_output_lines(instance, task, { "v2.0.0" })
  assert_eq(task.metadata.version, "2.0.0", "a new match should be captured after reset")
end)

test("no match leaves metadata untouched", function()
  local instance = component.constructor({ key = "version", pattern = "v(%d+%.%d+%.%d+)", first = true })
  local task = new_task()
  instance.on_output_lines(instance, task, { "no version here" })
  assert_eq(task.metadata, nil, "metadata table should not even be created when nothing matches")
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
