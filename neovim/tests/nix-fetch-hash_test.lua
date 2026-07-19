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
local RESOLVED_SHA = "1234567890abcdef1234567890abcdef12345678"

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

-- Stubs M.fetch_rev_hash to call back synchronously, recording every expr it
-- was invoked with. Returns (calls, restore).
local function stub_fetch_rev_hash(rev, hash, err)
  local calls = {}
  local orig = M.fetch_rev_hash
  M.fetch_rev_hash = function(expr, callback)
    table.insert(calls, expr)
    callback(rev, hash, err)
  end
  return calls, function()
    M.fetch_rev_hash = orig
  end
end

-- Runs fill_rev_and_hash and waits (via vim.notify interception) for a
-- terminal message, so the async conform.format() tail has settled before we
-- assert on buffer content. Returns the captured notify messages.
local function fill_rev_and_hash_and_wait(buf, row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  local messages = {}
  local done = false
  local orig_notify = vim.notify
  vim.notify = function(msg, level, opts)
    table.insert(messages, msg)
    if
      msg == "Updated rev and hash"
      or msg:match("^nix eval failed")
      or msg:match("formatting failed")
      or msg:match("syntax error")
      or msg:match("^No fetchFromGitHub")
      or msg:match("^Couldn't")
      or msg:match("^Buffer")
      or msg:match("must be plain strings")
      or msg:match("must be a plain string literal")
      or msg:match("already a full SHA%-1")
    then
      done = true
    end
  end
  M.fill_rev_and_hash(buf)
  local ok = vim.wait(5000, function()
    return done
  end, 20)
  vim.notify = orig_notify
  if not ok then
    error("timed out waiting for fill_rev_and_hash to settle; messages so far: " .. vim.inspect(messages))
  end
  return messages
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

test("replaces a `hash = null` value", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    "    hash = null;",
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(buf_text(buf), 'hash = "' .. FAKE_HASH .. '"', "hash = null should be replaced")
  assert_not_contains(buf_text(buf), "= null", "null placeholder should be gone")
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

-- owner/repo/rev resolution through scopes (variables, `let`, `inherit`)

test("resolves repo via a variable reference and rev via a bare `inherit`", function()
  local lines = {
    "let",
    '  pname = "codediff.nvim";',
    '  rev = "feat/dir-mode-path-filter";',
    "in",
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    "    repo = pname;",
    "    inherit rev;",
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(calls[1], 'owner = "dwf"', "owner should resolve to the plain string")
  assert_contains(calls[1], 'repo = "codediff.nvim"', "repo should resolve through the `pname` variable")
  assert_contains(calls[1], 'ref = "feat/dir-mode-path-filter"', "rev should resolve through the bare `inherit`")
  assert_contains(buf_text(buf), 'hash = "' .. FAKE_HASH .. '"', "hash should still be inserted correctly")
end)

test("resolves owner via `inherit (attrset) owner` from a sibling rec binding", function()
  local lines = {
    "rec {",
    "  extra = {",
    '    owner = "dwf";',
    "  };",
    "  src = pkgs.fetchFromGitHub {",
    "    inherit (extra) owner;",
    '    repo = "codediff.nvim";',
    '    rev = "feat/dir-mode-path-filter";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "repo")
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_hash call")
  assert_contains(calls[1], 'owner = "dwf"', "owner should resolve through inherit (extra) owner")
  assert_contains(buf_text(buf), 'hash = "' .. FAKE_HASH .. '"', "hash should still be inserted correctly")
end)

test("resolves a variable defined in terms of another variable (chained references)", function()
  local lines = {
    "let",
    '  baseName = "codediff.nvim";',
    "  pname = baseName;",
    "in",
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    "    repo = pname;",
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
  assert_contains(calls[1], 'repo = "codediff.nvim"', "repo should resolve through a chain of variable references")
end)

test("fails gracefully when a reference bottoms out in a function parameter", function()
  local lines = {
    "{ pname }:",
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    "    repo = pname;",
    '    rev = "feat/dir-mode-path-filter";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local before = buf_text(buf)
  local calls, restore = stub_fetch_hash(FAKE_HASH, nil)
  local messages = fill_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 0, "fetch_hash should not be called when repo can't be resolved to a literal")
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
  if not has_message(messages, "must be plain strings") then
    error("expected a 'must be plain strings' notification, got: " .. vim.inspect(messages))
  end
end)

-- fill_rev_and_hash: resolving a floating/missing rev to a concrete commit

test("resolves a branch name to a full sha and updates the hash", function()
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
  local calls, restore = stub_fetch_rev_hash(RESOLVED_SHA, FAKE_HASH, nil)
  fill_rev_and_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_rev_hash call")
  assert_contains(calls[1], 'ref = "feat/dir-mode-path-filter"', "branch name should be resolved via ref=")
  local text = buf_text(buf)
  assert_contains(text, 'rev = "' .. RESOLVED_SHA .. '"', "rev should be replaced with the resolved full sha")
  assert_contains(text, 'sha256 = "' .. FAKE_HASH .. '"', "sha256 should be refreshed to match the resolved rev")
end)

test("adds rev and hash when rev is missing, resolving the default branch", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_rev_hash(RESOLVED_SHA, FAKE_HASH, nil)
  fill_rev_and_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_rev_hash call")
  assert_not_contains(calls[1], "ref =", "missing rev should resolve the default branch, not pass a ref=")
  assert_not_contains(calls[1], "rev =", "missing rev should resolve the default branch, not pass a rev=")
  local text = buf_text(buf)
  assert_contains(text, 'rev = "' .. RESOLVED_SHA .. '"', "rev should be inserted with the resolved full sha")
  assert_contains(text, 'hash = "' .. FAKE_HASH .. '"', "hash should be inserted using the `hash` key")
end)

test("treats an empty-string rev the same as a missing one", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    '    rev = "";',
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_rev_hash(RESOLVED_SHA, FAKE_HASH, nil)
  fill_rev_and_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_rev_hash call")
  assert_not_contains(calls[1], "ref =", "empty-string rev should resolve the default branch, not pass a ref=")
  local text = buf_text(buf)
  assert_contains(text, 'rev = "' .. RESOLVED_SHA .. '"', "empty rev should be replaced with the resolved full sha")
  assert_contains(text, 'hash = "' .. FAKE_HASH .. '"', "hash should be inserted")
end)

test("treats a `rev = null` value the same as a missing one", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    "    rev = null;",
    "    sha256 = null;",
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local calls, restore = stub_fetch_rev_hash(RESOLVED_SHA, FAKE_HASH, nil)
  fill_rev_and_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 1, "expected exactly one fetch_rev_hash call")
  assert_not_contains(calls[1], "ref =", "null rev should resolve the default branch, not pass a ref=")
  local text = buf_text(buf)
  assert_contains(text, 'rev = "' .. RESOLVED_SHA .. '"', "null rev should be replaced with the resolved full sha")
  assert_contains(text, 'sha256 = "' .. FAKE_HASH .. '"', "sha256 = null should be replaced, preserving the sha256 key")
end)

test("does nothing when rev is already a full sha", function()
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
  local before = buf_text(buf)
  local calls, restore = stub_fetch_rev_hash(RESOLVED_SHA, FAKE_HASH, nil)
  local messages = fill_rev_and_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 0, "fetch_rev_hash should not be called when rev is already a full sha")
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
  if not has_message(messages, "already a full SHA%-1") then
    error("expected an 'already a full SHA-1' notification, got: " .. vim.inspect(messages))
  end
end)

test("fails gracefully when rev is not a plain string literal", function()
  local lines = {
    "{",
    "  src = pkgs.fetchFromGitHub {",
    '    owner = "dwf";',
    '    repo = "codediff.nvim";',
    "    rev = lib.someRev;",
    "  };",
    "}",
  }
  local buf = new_buffer(lines)
  local row, col = find_cursor(lines, "owner")
  local before = buf_text(buf)
  local calls, restore = stub_fetch_rev_hash(RESOLVED_SHA, FAKE_HASH, nil)
  local messages = fill_rev_and_hash_and_wait(buf, row, col)
  restore()
  assert_eq(#calls, 0, "fetch_rev_hash should not be called when rev isn't a plain string literal")
  assert_eq(buf_text(buf), before, "buffer should be unchanged")
  if not has_message(messages, "must be a plain string literal") then
    error("expected a 'must be a plain string literal' notification, got: " .. vim.inspect(messages))
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
