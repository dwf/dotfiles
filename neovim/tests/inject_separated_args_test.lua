-- Unit tests for
-- neovim/plugins/overseer-components/lua/overseer/component/inject_separated_args.lua
-- No overseer task runtime is needed: constructor(params) is called directly
-- and on_init is driven against a fake `task` table.
--
--   nvim --headless -c "lua dofile('neovim/tests/inject_separated_args_test.lua')"
--
-- Exits via :cquit (nonzero) if any test fails.

-- overseer-components is an optional (lazy) plugin, normally packadd-ed via
-- overseer's own before hook (see plugins/overseer.nix) - do it here too
-- since this test never loads overseer itself.
vim.cmd.packadd("overseer-components")
local component = require("overseer.component.inject_separated_args")

-- constructor(params) is called directly in these tests, bypassing
-- overseer's own param-schema defaulting (normally applied by
-- component.load()/instantiate() before constructor() ever runs) - so
-- tests exercising default behavior pass this explicitly rather than
-- relying on `optional`/`default` in the params schema.
local default_separator = component.params.separator.default

local tests = {}
local function test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

local function assert_eq(actual, expected, context)
  if not vim.deep_equal(actual, expected) then
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

test("table cmd: appends separator then args when no separator is present", function()
  local instance = component.constructor({
    separator = default_separator,
    callback = function()
      return { "extra_arg" }
    end,
  })
  local task = { cmd = { "echo", "hello" } }
  instance.on_init(instance, task)
  assert_eq(task.cmd, { "echo", "hello", "--", "extra_arg" })
end)

test("table cmd: does not duplicate an existing separator", function()
  local instance = component.constructor({
    separator = default_separator,
    callback = function()
      return { "extra_arg" }
    end,
  })
  local task = { cmd = { "echo", "hello", "--" } }
  instance.on_init(instance, task)
  assert_eq(task.cmd, { "echo", "hello", "--", "extra_arg" })
end)

test("string cmd: appends separator then args when no separator is present", function()
  local instance = component.constructor({
    separator = default_separator,
    callback = function()
      return { "extra_arg" }
    end,
  })
  local task = { cmd = "echo hello" }
  instance.on_init(instance, task)
  assert_eq(task.cmd, "echo hello -- extra_arg")
end)

test("string cmd: does not duplicate an existing separator", function()
  local instance = component.constructor({
    separator = default_separator,
    callback = function()
      return { "extra_arg" }
    end,
  })
  local task = { cmd = "echo hello --" }
  instance.on_init(instance, task)
  assert_eq(task.cmd, "echo hello -- extra_arg")
end)

test("callback returning a bare string is wrapped as a single arg", function()
  local instance = component.constructor({
    separator = default_separator,
    callback = function()
      return "extra_arg"
    end,
  })
  local task = { cmd = { "echo", "hello" } }
  instance.on_init(instance, task)
  assert_eq(task.cmd, { "echo", "hello", "--", "extra_arg" })
end)

test("separator param overrides the default '--'", function()
  local instance = component.constructor({
    separator = "++",
    callback = function()
      return { "extra_arg" }
    end,
  })
  local task = { cmd = { "echo", "hello" } }
  instance.on_init(instance, task)
  assert_eq(task.cmd, { "echo", "hello", "++", "extra_arg" })
end)

-- overseer.Task.new() calls both add_components() (which calls on_init
-- directly, since task.id is already assigned by that point) and then
-- dispatch("on_init") (which calls on_init on every component again), so
-- on_init genuinely fires twice per real task. Confirmed against a real
-- overseer.new_task() call before this was fixed: the separator was
-- deduped correctly but the injected arg itself appeared twice.
test("on_init is idempotent when called twice, as overseer.Task.new() actually does", function()
  local call_count = 0
  local instance = component.constructor({
    separator = default_separator,
    callback = function()
      call_count = call_count + 1
      return { "extra_arg" }
    end,
  })
  local task = { cmd = { "echo", "hello" } }
  instance.on_init(instance, task)
  instance.on_init(instance, task)
  assert_eq(call_count, 1, "callback should only be invoked once across both on_init calls")
  assert_eq(task.cmd, { "echo", "hello", "--", "extra_arg" }, "the arg should not be doubled")
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
