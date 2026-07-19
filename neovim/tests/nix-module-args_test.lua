-- Unit tests for lua/nix-module-args.lua. No external processes involved
-- (just buffer/treesitter edits plus an async conform.format() tail), so
-- these run directly in a nix build sandbox:
--
--   nvim --headless -c "lua dofile('neovim/tests/nix-module-args_test.lua')"
--
-- Exits via :cquit (nonzero) if any test fails.

local M = require("nix-module-args")

local tests = {}
local function test(name, fn)
  table.insert(tests, { name = name, fn = fn })
end

local function new_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, lines)
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].filetype = "nix"
  return buf
end

local function buf_text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), "\n")
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

local function assert_contains(s, needle, context)
  if not s:find(needle, 1, true) then
    error(string.format("%s:\n  string:   %s\n  does not contain: %s", context or "assertion failed", s, needle))
  end
end

local function assert_not_contains(s, needle, context)
  if s:find(needle, 1, true) then
    error(string.format("%s:\n  string:   %s\n  unexpectedly contains: %s", context or "assertion failed", s, needle))
  end
end

local function has_message(messages, pattern)
  for _, m in ipairs(messages) do
    if m:match(pattern) then
      return true
    end
  end
  return false
end

-- Runs ensure_arg. Returns (messages, raw_text): `raw_text` is the buffer
-- content captured immediately after the (synchronous) treesitter edit but
-- before conform's async reformat runs, so structural assertions don't
-- depend on nixfmt's exact layout choices. Also waits for a terminal
-- notify so the async tail settles before the next test starts.
local function ensure_arg_and_wait(buf, symbol)
  local messages = {}
  local done = false
  local orig_notify = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(messages, msg)
    if
      msg:match("^Added")
      or msg:match("formatting failed")
      or msg:match("already a parameter")
      or msg:match("^Buffer doesn't parse")
      or msg:match("bare identifier argument")
      or msg:match("isn't an attrset")
    then
      done = true
    end
  end
  M.ensure_arg(buf, symbol)
  local raw_text = buf_text(buf)
  local ok = vim.wait(5000, function()
    return done
  end, 20)
  vim.notify = orig_notify
  if not ok then
    error("timed out waiting for ensure_arg to settle; messages so far: " .. vim.inspect(messages))
  end
  return messages, raw_text
end

test("adds a header to a bare attrset", function()
  local buf = new_buffer({ "{", "  a = 1;", "}" })
  local messages, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(raw_text, "{ pkgs, ... }:\n{\n  a = 1;\n}", "should insert a new function header")
  if not has_message(messages, "^Added") then
    error("expected an 'Added' notification, got: " .. vim.inspect(messages))
  end
end)

test("adds a header to a rec attrset", function()
  local buf = new_buffer({ "rec {", "  a = 1;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(raw_text, "{ pkgs, ... }:\nrec {\n  a = 1;\n}", "should insert a header before `rec`")
end)

test("adds a header before a let-wrapped attrset", function()
  local buf = new_buffer({ "let", "  x = 1;", "in", "{", "  a = x;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(
    raw_text,
    "{ pkgs, ... }:\nlet\n  x = 1;\nin\n{\n  a = x;\n}",
    "should insert a header before the let"
  )
end)

test("adds a header before a with-wrapped attrset", function()
  local buf = new_buffer({ "with foo;", "{", "  a = 1;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(raw_text, "{ pkgs, ... }:\nwith foo;\n{\n  a = 1;\n}", "should insert a header before the with")
end)

test("adds a header before arbitrarily nested with/let layers", function()
  local buf = new_buffer({ "with foo;", "let", "  x = 1;", "in", "with bar;", "{", "  a = x;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_contains(raw_text, "{ pkgs, ... }:\nwith foo;", "header should precede all wrapping layers")
  assert_contains(raw_text, "with bar;", "inner with should be preserved")
end)

test("adds symbol to existing formals that have an ellipsis", function()
  local buf = new_buffer({ "{ a, ... }:", "{", "  b = a;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_contains(raw_text, "{ a, pkgs, ... }:", "pkgs should be inserted right before the ellipsis")
end)

test("adds symbol to existing formals without an ellipsis", function()
  local buf = new_buffer({ "{ a }:", "{", "  b = a;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_contains(raw_text, "{ a, pkgs }:", "pkgs should be appended after the last existing formal")
  assert_not_contains(raw_text, "...", "should not gain an ellipsis that wasn't there before")
end)

test("adds symbol to an empty formals list", function()
  local buf = new_buffer({ "{ }:", "{", "  b = 1;", "}" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_contains(raw_text, "pkgs", "pkgs should be added to the empty formals")
end)

test("does nothing when the symbol is already a parameter", function()
  local buf = new_buffer({ "{ pkgs, ... }:", "{", "  a = pkgs;", "}" })
  local before = buf_text(buf)
  local messages, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(raw_text, before, "buffer should be unchanged")
  if not has_message(messages, "already a parameter") then
    error("expected an 'already a parameter' notification, got: " .. vim.inspect(messages))
  end
end)

test("adds to the innermost function in a curried chain, not an outer one", function()
  local buf = new_buffer({
    "x:",
    "{ a, ... }:",
    "let",
    "  y = 1;",
    "in",
    "with foo;",
    "{ b, ... }:",
    "{",
    "  c = a + b + x + y;",
    "}",
  })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_contains(raw_text, "{ b, pkgs, ... }:", "innermost formals should gain pkgs")
  assert_not_contains(raw_text, "{ a, pkgs, ... }:", "outer formals should be untouched")
  assert_contains(raw_text, "{ a, ... }:", "outer formals should remain as they were")
end)

test("warns and does not edit when the innermost function takes a bare identifier", function()
  local buf = new_buffer({ "{ a, ... }:", "x:", "{", "  b = a + x;", "}" })
  local before = buf_text(buf)
  local messages, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(raw_text, before, "buffer should be unchanged")
  if not has_message(messages, "bare identifier argument") then
    error("expected a 'bare identifier argument' notification, got: " .. vim.inspect(messages))
  end
end)

test("warns and does not edit when there's no function and the top level isn't an attrset", function()
  local buf = new_buffer({ "[ 1 2 3 ]" })
  local before = buf_text(buf)
  local messages, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_eq(raw_text, before, "buffer should be unchanged")
  if not has_message(messages, "isn't an attrset") then
    error("expected an 'isn't an attrset' notification, got: " .. vim.inspect(messages))
  end
end)

test("adds a parameter to an existing function even when its body isn't an attrset", function()
  local buf = new_buffer({ "{ a, ... }:", "[ a 1 2 ]" })
  local _, raw_text = ensure_arg_and_wait(buf, "pkgs")
  assert_contains(raw_text, "{ a, pkgs, ... }:", "pkgs should be added regardless of what the function returns")
end)

-- prune_empty_arg: the inverse operation, cleaning up an unused header

test("prunes a `{ ... }:` header with no real parameters", function()
  local buf = new_buffer({ "{ ... }:", "{", "  a = 1;", "}" })
  M.prune_empty_arg(buf)
  assert_eq(buf_text(buf), "{\n  a = 1;\n}", "the whole header should be removed")
end)

test("prunes a `{ }:` header (no ellipsis, no formals)", function()
  local buf = new_buffer({ "{ }:", "{", "  a = 1;", "}" })
  M.prune_empty_arg(buf)
  assert_eq(buf_text(buf), "{\n  a = 1;\n}", "the whole header should be removed")
end)

test("does not prune a header that has a real parameter", function()
  local buf = new_buffer({ "{ a, ... }:", "{", "  b = a;", "}" })
  local before = buf_text(buf)
  M.prune_empty_arg(buf)
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
end)

test("does nothing when there's no function at all", function()
  local buf = new_buffer({ "{", "  a = 1;", "}" })
  local before = buf_text(buf)
  M.prune_empty_arg(buf)
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
end)

test("does nothing when the innermost function is a bare identifier", function()
  local buf = new_buffer({ "x:", "{", "  a = x;", "}" })
  local before = buf_text(buf)
  M.prune_empty_arg(buf)
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
end)

test("prunes only the innermost empty header in a curried chain", function()
  local buf = new_buffer({ "{ a, ... }:", "{ ... }:", "{", "  b = a;", "}" })
  M.prune_empty_arg(buf)
  assert_eq(
    buf_text(buf),
    "{ a, ... }:\n{\n  b = a;\n}",
    "only the innermost empty header should be removed; the outer one is untouched"
  )
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
