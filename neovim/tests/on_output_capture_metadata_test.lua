-- Unit tests for
-- neovim/plugins/overseer-components/lua/overseer/component/on_output_capture_metadata.lua
-- No overseer task runtime is needed: constructor(params) is called directly
-- and on_reset/on_output_lines are driven against a fake `task` table.
--
--   nvim --headless -c "lua dofile('neovim/tests/on_output_capture_metadata_test.lua')"
--
-- Exits via :cquit (nonzero) if any test fails.

-- overseer-components is an optional (lazy) plugin, normally packadd-ed via
-- overseer's own before hook (see plugins/overseer.nix) - do it here too
-- since this test never loads overseer itself.
vim.cmd.packadd("overseer-components")
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
  local instance = component.constructor({ keys = { version = { pattern = "v(%d+%.%d+%.%d+)", first = true } } })
  local task = new_task()
  instance.on_output_lines(instance, task, { "building...", "release v1.2.3 ready" })
  assert_eq(task.metadata.version, "1.2.3", "first match should be captured")
  instance.on_output_lines(instance, task, { "release v9.9.9 ready" })
  assert_eq(task.metadata.version, "1.2.3", "later matches should be ignored once first = true has matched")
end)

test("first = true stops scanning the rest of the same batch once matched", function()
  local instance = component.constructor({ keys = { version = { pattern = "v(%d+%.%d+%.%d+)", first = true } } })
  local task = new_task()
  instance.on_output_lines(instance, task, { "v1.0.0", "v2.0.0", "v3.0.0" })
  assert_eq(task.metadata.version, "1.0.0", "should stop at the first match in the batch")
end)

test("first defaults to true when omitted", function()
  local instance = component.constructor({ keys = { version = { pattern = "v(%d+%.%d+%.%d+)" } } })
  local task = new_task()
  instance.on_output_lines(instance, task, { "v1.0.0", "v2.0.0" })
  assert_eq(task.metadata.version, "1.0.0", "first should default to true")
end)

test("first = false keeps updating metadata on every subsequent match", function()
  local instance = component.constructor({ keys = { version = { pattern = "v(%d+%.%d+%.%d+)", first = false } } })
  local task = new_task()
  instance.on_output_lines(instance, task, { "v1.0.0", "v2.0.0" })
  assert_eq(task.metadata.version, "2.0.0", "metadata should reflect the last match in the batch")
  instance.on_output_lines(instance, task, { "v3.0.0" })
  assert_eq(task.metadata.version, "3.0.0", "metadata should keep updating on later calls")
end)

test("different key/pattern pairs on separate instances are independent", function()
  local build_instance = component.constructor({ keys = { build_number = { pattern = "Build #(%d+)", first = true } } })
  local task = new_task()
  build_instance.on_output_lines(build_instance, task, { "Starting", "Build #42 complete" })
  assert_eq(task.metadata.build_number, "42", "build_number should be captured from its own pattern")

  local branch_instance = component.constructor({ keys = { branch = { pattern = "^On branch (%S+)", first = true } } })
  branch_instance.on_output_lines(branch_instance, task, { "On branch main", "nothing to commit" })
  assert_eq(task.metadata.branch, "main", "branch should be captured from its own pattern")
  assert_eq(task.metadata.build_number, "42", "capturing a second key should not disturb the first")
end)

test("a single instance can capture multiple keys with independent patterns and first settings", function()
  local instance = component.constructor({
    keys = {
      build_number = { pattern = "Build #(%d+)", first = true },
      version = { pattern = "v(%d+%.%d+%.%d+)", first = false },
    },
  })
  local task = new_task()
  instance.on_output_lines(instance, task, { "Build #1 v1.0.0", "Build #2 v2.0.0" })
  assert_eq(task.metadata.build_number, "1", "build_number has first = true, so only the first match sticks")
  assert_eq(task.metadata.version, "2.0.0", "version has first = false, so the last match in the batch wins")

  instance.on_output_lines(instance, task, { "Build #3 v3.0.0" })
  assert_eq(task.metadata.build_number, "1", "build_number should still be ignoring further matches")
  assert_eq(task.metadata.version, "3.0.0", "version should keep updating on later calls")
end)

test("each key's own callback fires with the task, independent of other keys", function()
  local calls = {}
  local instance = component.constructor({
    keys = {
      build_number = {
        pattern = "Build #(%d+)",
        first = true,
        callback = function(task)
          table.insert(calls, { key = "build_number", value = task.metadata.build_number })
        end,
      },
      version = {
        pattern = "v(%d+%.%d+%.%d+)",
        first = true,
        callback = function(task)
          table.insert(calls, { key = "version", value = task.metadata.version })
        end,
      },
    },
  })
  local task = new_task()
  instance.on_output_lines(instance, task, { "Build #1 v1.0.0" })
  table.sort(calls, function(a, b)
    return a.key < b.key
  end)
  assert_eq(#calls, 2, "each key's callback should fire once when it matches")
  assert_eq(calls[1].key, "build_number", "first callback (sorted) should be for build_number")
  assert_eq(calls[1].value, "1", "callback should see metadata already set for build_number")
  assert_eq(calls[2].key, "version", "second callback (sorted) should be for version")
  assert_eq(calls[2].value, "1.0.0", "callback should see metadata already set for version")
end)

test("a key without a callback doesn't error, and other keys' callbacks still fire", function()
  local calls = {}
  local instance = component.constructor({
    keys = {
      build_number = { pattern = "Build #(%d+)", first = true },
      version = {
        pattern = "v(%d+%.%d+%.%d+)",
        first = true,
        callback = function(task)
          table.insert(calls, { key = "version", value = task.metadata.version })
        end,
      },
    },
  })
  local task = new_task()
  instance.on_output_lines(instance, task, { "Build #1 v1.0.0" })
  assert_eq(task.metadata.build_number, "1", "build_number should still be captured without a callback")
  assert_eq(#calls, 1, "only version's callback should have fired")
  assert_eq(calls[1].key, "version", "the callback that fired should be for version")
end)

test("on_reset clears every configured metadata key and allows re-matching", function()
  local instance = component.constructor({
    keys = {
      build_number = { pattern = "Build #(%d+)", first = true },
      version = { pattern = "v(%d+%.%d+%.%d+)", first = true },
    },
  })
  local task = new_task()
  instance.on_output_lines(instance, task, { "Build #1 v1.0.0" })
  assert_eq(task.metadata.build_number, "1", "sanity check: build_number captured")
  assert_eq(task.metadata.version, "1.0.0", "sanity check: version captured")

  instance.on_reset(instance, task)
  assert_eq(task.metadata.build_number, nil, "on_reset should clear build_number")
  assert_eq(task.metadata.version, nil, "on_reset should clear version")

  instance.on_output_lines(instance, task, { "Build #2 v2.0.0" })
  assert_eq(task.metadata.build_number, "2", "a new match should be captured after reset")
  assert_eq(task.metadata.version, "2.0.0", "a new match should be captured after reset")
end)

test("no match leaves metadata untouched", function()
  local instance = component.constructor({ keys = { version = { pattern = "v(%d+%.%d+%.%d+)", first = true } } })
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
