-- Unit tests for lua/nix-fetch-hash.lua. `nix eval` is stubbed via
-- M.fetch_hash, so these need no network access and can run inside a nix
-- build sandbox. Run against the flake's `neovim` package, which already has
-- the nix treesitter parser + conform.nvim + lz.n on the runtimepath:
--
--   nvim --headless -c "lua dofile('neovim/tests/nix-fetch-hash_test.lua')"
--
-- Exits via :cquit (nonzero) if any test fails.

local M = require("nix-fetch-hash")

local FAKE_HASH = "sha256-FAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAK="
local OLD_HASH = "sha256-OLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLD="

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

-- 1-indexed row / 0-indexed col of the first occurrence of `needle`, matching
-- nvim_win_set_cursor's expectations.
local function find_cursor(lines, needle)
  for i, line in ipairs(lines) do
    local col = line:find(needle, 1, true)
    if col then
      return i, col - 1
    end
  end
  error("needle not found in buffer: " .. needle)
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

local function assert_match(s, pattern, context)
  if not s:match(pattern) then
    error(string.format("%s:\n  string:  %s\n  does not match pattern: %s", context or "assertion failed", s, pattern))
  end
end

-- Plain (non-pattern) substring checks, for asserting on literal strings
-- like hashes that contain Lua pattern magic characters (e.g. `-`).
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

-- Stubs M.fetch_hash to call back synchronously, recording every expr it was
-- invoked with. Returns (calls, restore).
local function stub_fetch_hash(hash, err)
  local calls = {}
  local orig = M.fetch_hash
  M.fetch_hash = function(expr, callback)
    table.insert(calls, expr)
    callback(hash, err)
  end
  return calls, function()
    M.fetch_hash = orig
  end
end

-- Runs fill_hash and waits (via vim.notify interception) for a terminal
-- message, so the async conform.format() tail has settled before we assert
-- on buffer content. Returns the captured notify messages.
local function fill_hash_and_wait(buf, row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  local messages = {}
  local done = false
  local orig_notify = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(messages, msg)
    if
      msg == "Updated hash"
      or msg:match("^nix eval failed")
      or msg:match("formatting failed")
      or msg:match("syntax error")
      or msg:match("^No fetchFromGitHub")
      or msg:match("^Couldn't")
      or msg:match("^Buffer")
      or msg:match("must be plain strings")
    then
      done = true
    end
  end
  M.fill_hash(buf)
  local ok = vim.wait(5000, function()
    return done
  end, 20)
  vim.notify = orig_notify
  if not ok then
    error("timed out waiting for fill_hash to settle; messages so far: " .. vim.inspect(messages))
  end
  return messages
end

local function has_message(messages, pattern)
  for _, m in ipairs(messages) do
    if m:match(pattern) then
      return true
    end
  end
  return false
end

test("replaces an existing sha256 value", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    '    sha256 = "' .. OLD_HASH .. '";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  local ok, err = pcall(fill_hash_and_wait, buf, row, col)
  restore()
  if not ok then
    error(err)
  end
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(buf_text(buf), 'sha256 = "' .. FAKE_HASH .. '"', "buffer should contain new hash under sha256 key")
end)

test("preserves an existing `hash` key rather than switching to sha256", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    '    hash = "' .. OLD_HASH .. '";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(buf_text(buf), 'hash = "' .. FAKE_HASH .. '"', "buffer should keep hash key")
  -- The hash value itself legitimately contains the substring "sha256"
  -- (SRI format), so check specifically for a `sha256 =` attribute key.
  assert_not_contains(buf_text(buf), "sha256 =", "buffer should not have gained a sha256 key")
end)

test("replaces an empty-string sha256 value", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    '    sha256 = "";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(buf_text(buf), 'sha256 = "' .. FAKE_HASH .. '"', "empty sha256 should be filled in")
end)

test("replaces a lib.fakeHash value", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    "    hash = lib.fakeHash;",
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(buf_text(buf), 'hash = "' .. FAKE_HASH .. '"', "lib.fakeHash should be replaced")
  assert_not_contains(buf_text(buf), "fakeHash", "lib.fakeHash reference should be gone")
end)

test("inserts a new `hash` attribute (not sha256) when none exists, and reformats", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  local text = buf_text(buf)
  assert_contains(text, 'hash = "' .. FAKE_HASH .. '";', "new hash attribute should use `hash`, not `sha256`")
  -- nixfmt should have given the new binding its own, properly indented line.
  assert_match(
    text,
    '\n%s+hash = "' .. vim.pesc(FAKE_HASH) .. '";\n',
    "conform/nixfmt should put the new binding on its own line"
  )
end)

test("uses `ref` for a branch name", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_contains(calls[1], 'ref = "feat/dir-mode-path-filter"', "branch name should be passed as ref=")
  assert_not_contains(calls[1], 'rev = "feat', "branch name should not be passed as rev=")
end)

test("uses `rev` for a full 40-char commit sha", function()
  local sha = "4bbb0e82e92c350bfb2e69ccc4806a00242823f7"
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "' .. sha .. '";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_contains(calls[1], 'rev = "' .. sha .. '"', "full sha should be passed as rev=")
end)

test("leaves the buffer untouched and notifies when nix eval fails", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    '    sha256 = "' .. OLD_HASH .. '";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local before = buf_text(buf)
  local calls, restore = stub_fetch_hash(nil, "boom: rev not found")
  local messages = fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_eq(buf_text(buf), before, "buffer should be unchanged on fetch failure")
  if not has_message(messages, "^nix eval failed") then
    error("expected a 'nix eval failed' notification, got: " .. vim.inspect(messages))
  end
end)

test("fails fast on a syntax error without calling fetch_hash", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim"', -- missing semicolon: syntax error
    '    rev = "feat/dir-mode-path-filter";',
    '    sha256 = "' .. OLD_HASH .. '";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local before = buf_text(buf)
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  local messages = fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 0, "fetch_hash should not be called when the call has a syntax error")
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
  if not has_message(messages, "syntax error") then
    error("expected a syntax-error notification, got: " .. vim.inspect(messages))
  end
end)

test("does nothing when the cursor is outside any fetchFromGitHub call", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    '    sha256 = "' .. OLD_HASH .. '";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local before = buf_text(buf)
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  local messages = fill_hash_and_wait(buf, 1, 0)
  restore()
  assert_eq(#calls, 0, "fetch_hash should not be called")
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
  if not has_message(messages, "^No fetchFromGitHub") then
    error("expected a 'No fetchFromGitHub' notification, got: " .. vim.inspect(messages))
  end
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
