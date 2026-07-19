local M = {}

local KNOWN_FETCHERS = {
  fetchFromGitHub = "github",
}

local function node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

local function fetcher_name(call)
  local fn = call:field("function")[1]
  if not fn then
    return nil
  end
  if fn:type() == "variable_expression" then
    local name = fn:field("name")[1]
    return name and node_text(name, 0)
  elseif fn:type() == "select_expression" then
    local attrpath = fn:field("attrpath")[1]
    if not attrpath then
      return nil
    end
    local attrs = attrpath:field("attr")
    local last = attrs[#attrs]
    return last and node_text(last, 0)
  end
  return nil
end

local function find_call_at(bufnr, row, col)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "nix")
  if not ok then
    return nil
  end
  local tree = parser:parse()[1]
  local node = tree:root():named_descendant_for_range(row, col, row, col)
  while node do
    if node:type() == "apply_expression" and KNOWN_FETCHERS[fetcher_name(node)] then
      return node
    end
    node = node:parent()
  end
  return nil
end

local function string_fragment(node)
  if not node or node:type() ~= "string_expression" then
    return nil
  end
  if node:named_child_count() ~= 1 then
    return nil
  end
  local frag = node:named_child(0)
  if frag:type() ~= "string_fragment" then
    return nil
  end
  return frag
end

-- tree-sitter-nix has no dedicated node type for `null` (or `true`/`false`)
-- — it's just an identifier, parsed the same as any other variable
-- reference. Semantics are entirely up to the evaluator.
local function is_null_literal(node, bufnr)
  if not node or node:type() ~= "variable_expression" then
    return false
  end
  local name_node = node:field("name")[1]
  return name_node ~= nil and node_text(name_node, bufnr) == "null"
end

local function is_attrset(node)
  local t = node and node:type()
  return t == "attrset_expression" or t == "rec_attrset_expression"
end

local function get_bindings(call, bufnr)
  local arg = call:field("argument")[1]
  if not is_attrset(arg) then
    return nil
  end
  local bindings = {}
  for child in arg:iter_children() do
    if child:type() == "binding_set" then
      for binding in child:iter_children() do
        if binding:type() == "binding" then
          local attrpath = binding:field("attrpath")[1]
          local attrs = attrpath and attrpath:field("attr")
          if attrs and #attrs == 1 then
            local key = node_text(attrs[1], bufnr)
            bindings[key] = {
              binding = binding,
              value = binding:field("expression")[1],
            }
          end
        end
      end
    end
  end
  return bindings
end

local function node_key(node)
  return table.concat({ node:range() }, ":")
end

local function binding_set_of(node)
  for child in node:iter_children() do
    if child:type() == "binding_set" then
      return child
    end
  end
  return nil
end

-- Last direct child of a binding_set (binding, inherit, or inherit_from),
-- used as the insertion anchor for a new attribute — independent of which
-- particular attribute names exist, since owner/repo/rev may now be
-- brought in via `inherit` rather than a plain binding.
local function last_binding_set_child(binding_set)
  local last
  for child in binding_set:iter_children() do
    last = child
  end
  return last
end

-- Look for a direct `name = expr;` binding, `inherit name;`, or
-- `inherit (src) name;` as an immediate child of a binding_set. Doesn't
-- resolve further — just describes what kind of thing was found.
local function find_in_binding_set(binding_set, name, bufnr)
  for child in binding_set:iter_children() do
    local t = child:type()
    if t == "binding" then
      local attrpath = child:field("attrpath")[1]
      local attrs = attrpath and attrpath:field("attr")
      if attrs and #attrs == 1 and node_text(attrs[1], bufnr) == name then
        return { kind = "binding", node = child:field("expression")[1] }
      end
    elseif t == "inherit" or t == "inherit_from" then
      local attrs_node = child:field("attrs")[1]
      for _, attr in ipairs(attrs_node and attrs_node:field("attr") or {}) do
        if node_text(attr, bufnr) == name then
          return { kind = t, source = child:field("expression")[1] }
        end
      end
    end
  end
  return nil
end

-- Forward declarations: resolve_string, resolve_attrset, resolve_name_in_scope
-- and lookup_attr_in_attrset are mutually recursive (an `inherit`/variable
-- reference may bottom out in an attribute access, which may itself need a
-- variable resolved, and so on).
local resolve_string, resolve_attrset, resolve_name_in_scope, lookup_attr_in_attrset

-- Climb the scopes enclosing `start_node` (let-bindings, rec-attrset
-- siblings, function parameters) looking for a lexical binding of `name`.
-- Returns the raw (unresolved) expression node bound to `name`, or nil if
-- it's unresolvable (a function parameter, a `with`, or just not found).
function resolve_name_in_scope(start_node, name, bufnr, seen)
  local node = start_node:parent()
  while node do
    local t = node:type()
    if t == "let_expression" or t == "rec_attrset_expression" then
      local binding_set = binding_set_of(node)
      local found = binding_set and find_in_binding_set(binding_set, name, bufnr)
      if found then
        if found.kind == "binding" then
          return found.node
        elseif found.kind == "inherit" then
          -- Plain `inherit name;` pulls from the scope enclosing this one,
          -- not from this scope's own bindings.
          return resolve_name_in_scope(node, name, bufnr, seen)
        else -- inherit_from
          local src = resolve_attrset(found.source, bufnr, seen)
          return src and lookup_attr_in_attrset(src, name, bufnr, seen)
        end
      end
    elseif t == "function_expression" then
      local formals = node:field("formals")[1]
      if formals then
        for _, formal in ipairs(formals:field("formal")) do
          local fname = formal:field("name")[1]
          if fname and node_text(fname, bufnr) == name then
            return nil -- function parameter: shadows outer scopes, no static value
          end
        end
      end
    end
    node = node:parent()
  end
  return nil
end

-- Single-level attribute lookup (`attrset.name`), not a scope climb.
function lookup_attr_in_attrset(attrset_node, name, bufnr, seen)
  local binding_set = binding_set_of(attrset_node)
  local found = binding_set and find_in_binding_set(binding_set, name, bufnr)
  if not found then
    return nil
  end
  if found.kind == "binding" then
    return found.node
  elseif found.kind == "inherit" then
    return resolve_name_in_scope(attrset_node, name, bufnr, seen)
  else -- inherit_from
    local src = resolve_attrset(found.source, bufnr, seen)
    return src and lookup_attr_in_attrset(src, name, bufnr, seen)
  end
end

-- Best-effort resolution of an expression node down to an attrset node,
-- following variable/attribute references through enclosing scopes.
function resolve_attrset(node, bufnr, seen)
  if not node then
    return nil
  end
  local key = node_key(node)
  if seen[key] then
    return nil
  end
  seen[key] = true

  if is_attrset(node) then
    return node
  elseif node:type() == "variable_expression" then
    local name_node = node:field("name")[1]
    local name = name_node and node_text(name_node, bufnr)
    return name and resolve_attrset(resolve_name_in_scope(node, name, bufnr, seen), bufnr, seen)
  elseif node:type() == "select_expression" then
    local base = node:field("expression")[1]
    local attrpath = node:field("attrpath")[1]
    if not base or not attrpath then
      return nil
    end
    local current = resolve_attrset(base, bufnr, seen)
    for _, attr_node in ipairs(attrpath:field("attr")) do
      if not current then
        return nil
      end
      local val = lookup_attr_in_attrset(current, node_text(attr_node, bufnr), bufnr, seen)
      current = val and resolve_attrset(val, bufnr, seen)
    end
    return current
  end
  return nil
end

-- Best-effort resolution of an expression node down to a plain string
-- value, following variable references and attribute access (`a.b.c`)
-- through enclosing scopes and `inherit` statements.
function resolve_string(node, bufnr, seen)
  if not node then
    return nil
  end
  local key = node_key(node)
  if seen[key] then
    return nil
  end
  seen[key] = true

  local t = node:type()
  if t == "string_expression" then
    local frag = string_fragment(node)
    return frag and node_text(frag, bufnr)
  elseif t == "variable_expression" then
    local name_node = node:field("name")[1]
    local name = name_node and node_text(name_node, bufnr)
    return name and resolve_string(resolve_name_in_scope(node, name, bufnr, seen), bufnr, seen)
  elseif t == "select_expression" then
    local base = node:field("expression")[1]
    local attrpath = node:field("attrpath")[1]
    if not base or not attrpath then
      return nil
    end
    local attrs = attrpath:field("attr")
    local current = resolve_attrset(base, bufnr, seen)
    for i, attr_node in ipairs(attrs) do
      if not current then
        return nil
      end
      local val = lookup_attr_in_attrset(current, node_text(attr_node, bufnr), bufnr, seen)
      if not val then
        return nil
      end
      if i == #attrs then
        return resolve_string(val, bufnr, seen)
      end
      current = resolve_attrset(val, bufnr, seen)
    end
  end
  return nil
end

-- Resolve `key` as it would be seen inside `arg_attrset` (the fetcher call's
-- argument attrset): a direct string, a variable/attribute reference, or an
-- `inherit`/`inherit_from` pulling it in from an enclosing scope.
local function resolve_field(arg_attrset, key, bufnr)
  local seen = {}
  local val = lookup_attr_in_attrset(arg_attrset, key, bufnr, seen)
  return val and resolve_string(val, bufnr, seen)
end

local function nix_string_literal(s)
  return '"' .. s:gsub('[\\"$]', "\\%0") .. '"'
end

local function is_full_sha(s)
  return #s == 40 and s:match("^%x+$") ~= nil
end

-- Re-locate the fetcher call via `mark_id` after an async edit, checking it
-- still parses cleanly. Returns (call, nil) or (nil, error_message).
local function relocate_call(bufnr, ns, mark_id)
  local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, { details = true })
  if #mark == 0 then
    return nil, "Buffer changed too much to relocate the fetcher call"
  end
  local call = find_call_at(bufnr, mark[1], mark[2])
  if not call then
    return nil, "Couldn't relocate fetcher call after edit"
  end
  if call:has_error() then
    return nil, "Buffer was edited to have a syntax error; changes not applied"
  end
  return call
end

-- Replace `key`'s existing value in `bindings` (if present) or insert a new
-- `key = value_text;` binding at the end of the fetcher call's argument
-- attrset. Returns true on success, false if no insertion point was found.
local function set_attr(bufnr, call, bindings, key, value_text)
  local existing = bindings[key]
  if existing then
    -- Replace the whole value node, not just a string_fragment: it may be
    -- an empty string (no fragment child) or a non-string expression like
    -- `lib.fakeHash`.
    local vs_row, vs_col, ve_row, ve_col = existing.value:range()
    vim.api.nvim_buf_set_text(bufnr, vs_row, vs_col, ve_row, ve_col, { value_text })
    return true
  end
  local binding_set = binding_set_of(call:field("argument")[1])
  local anchor = binding_set and last_binding_set_child(binding_set)
  if not anchor then
    return false
  end
  local _, _, a_end_row, a_end_col = anchor:range()
  vim.api.nvim_buf_set_text(
    bufnr,
    a_end_row,
    a_end_col,
    a_end_row,
    a_end_col,
    { string.format(" %s = %s;", key, value_text) }
  )
  return true
end

-- Deletes `mark_id` and reformats the range it spanned, notifying on
-- success/failure. `subject` names what was changed, e.g. "hash".
local function reformat_and_notify(bufnr, ns, mark_id, subject)
  local mark_after = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, { details = true })
  vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
  require("lz.n").trigger_load("conform.nvim")
  require("conform").format({
    bufnr = bufnr,
    async = true,
    range = {
      ["start"] = { mark_after[1] + 1, mark_after[2] },
      ["end"] = { mark_after[3].end_row + 1, mark_after[3].end_col },
    },
  }, function(err)
    if err then
      vim.notify("Updated " .. subject .. ", but formatting failed: " .. err, vim.log.levels.WARN)
    else
      vim.notify("Updated " .. subject, vim.log.levels.INFO)
    end
  end)
end

-- Overridable seam: tests stub this out to avoid a real `nix eval` (network,
-- non-deterministic latency). callback(hash, err) — exactly one is non-nil.
function M.fetch_hash(expr, callback)
  vim.system(
    { "nix", "eval", "--impure", "--raw", "--expr", expr },
    { text = true },
    vim.schedule_wrap(function(obj)
      if obj.code ~= 0 then
        callback(nil, obj.stderr or "")
      else
        callback(vim.trim(obj.stdout), nil)
      end
    end)
  )
end

function M.fill_hash(bufnr)
  bufnr = bufnr or 0
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local call = find_call_at(bufnr, row, col)
  if not call then
    vim.notify("No fetchFromGitHub call found at cursor", vim.log.levels.WARN)
    return
  end
  if call:has_error() then
    vim.notify("Fetcher call has a syntax error; fix it before filling in the hash", vim.log.levels.WARN)
    return
  end
  local fetch_type = KNOWN_FETCHERS[fetcher_name(call)]

  local arg = call:field("argument")[1]
  local bindings = get_bindings(call, bufnr)
  if not bindings then
    vim.notify("Couldn't parse fetcher argument attrset", vim.log.levels.WARN)
    return
  end

  local owner = resolve_field(arg, "owner", bufnr)
  local repo = resolve_field(arg, "repo", bufnr)
  local rev = resolve_field(arg, "rev", bufnr)
  if not (owner and repo and rev) then
    vim.notify("owner/repo/rev must be plain strings, or resolvable references to them", vim.log.levels.WARN)
    return
  end

  local hash_key = bindings.sha256 and "sha256" or (bindings.hash and "hash" or nil)

  local ns = vim.api.nvim_create_namespace("nix_fetch_hash")
  local s_row, s_col, e_row, e_col = call:range()
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, s_row, s_col, { end_row = e_row, end_col = e_col })

  local rev_field = is_full_sha(rev) and ("rev = " .. nix_string_literal(rev)) or ("ref = " .. nix_string_literal(rev))
  local expr = string.format(
    '(builtins.fetchTree { type = "%s"; owner = %s; repo = %s; %s; }).narHash',
    fetch_type,
    nix_string_literal(owner),
    nix_string_literal(repo),
    rev_field
  )

  vim.notify(string.format("Fetching hash for %s/%s@%s...", owner, repo, rev), vim.log.levels.INFO)

  M.fetch_hash(expr, function(hash, err)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    if err then
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      vim.notify("nix eval failed: " .. err, vim.log.levels.ERROR)
      return
    end

    -- Re-resolve against the current tree: the buffer may have been
    -- edited while the async `nix eval` was in flight, so any node
    -- captured before that point is no longer valid.
    local call2, relocate_err = relocate_call(bufnr, ns, mark_id)
    if not call2 then
      vim.notify(relocate_err, vim.log.levels.ERROR)
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      return
    end
    local bindings2 = get_bindings(call2, bufnr)
    if not set_attr(bufnr, call2, bindings2, hash_key or "hash", nix_string_literal(hash)) then
      vim.notify("Couldn't find an anchor to insert the hash attribute", vim.log.levels.ERROR)
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      return
    end

    reformat_and_notify(bufnr, ns, mark_id, "hash")
  end)
end

-- Overridable seam: tests stub this out to avoid a real `nix eval`.
-- `fetchTree`'s result carries both the resolved rev and its narHash, so
-- one call gets us both. callback(rev, hash, err) — err is nil on success.
function M.fetch_rev_hash(expr, callback)
  vim.system(
    { "nix", "eval", "--impure", "--json", "--expr", expr },
    { text = true },
    vim.schedule_wrap(function(obj)
      if obj.code ~= 0 then
        callback(nil, nil, obj.stderr or "")
        return
      end
      local ok, decoded = pcall(vim.json.decode, obj.stdout)
      if not ok or type(decoded) ~= "table" or type(decoded.rev) ~= "string" or type(decoded.narHash) ~= "string" then
        callback(nil, nil, "unexpected nix eval output: " .. obj.stdout)
        return
      end
      callback(decoded.rev, decoded.narHash, nil)
    end)
  )
end

-- Resolves `rev` to a full commit SHA-1 and refreshes the hash to match: if
-- `rev` is a branch/tag name, resolves that ref's tip; if `rev` is absent
-- (or a placeholder — an empty string or `null`), resolves the default
-- branch's tip. Does nothing if `rev` is already a full SHA-1 — use
-- `fill_hash` (the <leader>nh keymap) to just refresh the hash for an
-- already-pinned rev.
function M.fill_rev_and_hash(bufnr)
  bufnr = bufnr or 0
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local call = find_call_at(bufnr, row, col)
  if not call then
    vim.notify("No fetchFromGitHub call found at cursor", vim.log.levels.WARN)
    return
  end
  if call:has_error() then
    vim.notify("Fetcher call has a syntax error; fix it before resolving rev", vim.log.levels.WARN)
    return
  end
  local fetch_type = KNOWN_FETCHERS[fetcher_name(call)]

  local arg = call:field("argument")[1]
  local bindings = get_bindings(call, bufnr)
  if not bindings then
    vim.notify("Couldn't parse fetcher argument attrset", vim.log.levels.WARN)
    return
  end

  local owner = resolve_field(arg, "owner", bufnr)
  local repo = resolve_field(arg, "repo", bufnr)
  if not (owner and repo) then
    vim.notify("owner/repo must be plain strings, or resolvable references to them", vim.log.levels.WARN)
    return
  end

  -- Unlike owner/repo, `rev` must be a direct plain string (or absent/
  -- empty/null) here: we're about to overwrite it in this attrset, and a
  -- value that actually lives elsewhere (a variable, an `inherit`) isn't
  -- something we can safely rewrite in place.
  local rev_text = nil
  if bindings.rev then
    local value = bindings.rev.value
    local frag = string_fragment(value)
    if frag then
      rev_text = node_text(frag, bufnr)
    elseif value:type() == "string_expression" or is_null_literal(value, bufnr) then
      -- empty-string or `null` placeholder, treated like "absent" below.
    else
      vim.notify("rev must be a plain string literal (or absent/empty/null) to resolve it", vim.log.levels.WARN)
      return
    end
  end

  if rev_text and is_full_sha(rev_text) then
    vim.notify("rev is already a full SHA-1 commit hash; use <leader>nh to just refresh the hash", vim.log.levels.INFO)
    return
  end

  local hash_key = bindings.sha256 and "sha256" or (bindings.hash and "hash" or nil)

  local ns = vim.api.nvim_create_namespace("nix_fetch_hash")
  local s_row, s_col, e_row, e_col = call:range()
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, s_row, s_col, { end_row = e_row, end_col = e_col })

  local ref_field = rev_text and ("ref = " .. nix_string_literal(rev_text) .. ";") or ""
  local expr = string.format(
    'let r = builtins.fetchTree { type = "%s"; owner = %s; repo = %s; %s }; in { inherit (r) rev narHash; }',
    fetch_type,
    nix_string_literal(owner),
    nix_string_literal(repo),
    ref_field
  )

  vim.notify(
    string.format("Resolving rev for %s/%s%s...", owner, repo, rev_text and ("@" .. rev_text) or " (default branch)"),
    vim.log.levels.INFO
  )

  M.fetch_rev_hash(expr, function(rev, hash, err)
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return
    end
    if err then
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      vim.notify("nix eval failed: " .. err, vim.log.levels.ERROR)
      return
    end

    local call2, relocate_err = relocate_call(bufnr, ns, mark_id)
    if not call2 then
      vim.notify(relocate_err, vim.log.levels.ERROR)
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      return
    end
    local bindings2 = get_bindings(call2, bufnr)
    if not set_attr(bufnr, call2, bindings2, "rev", nix_string_literal(rev)) then
      vim.notify("Couldn't find an anchor to insert the rev attribute", vim.log.levels.ERROR)
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      return
    end

    -- Re-relocate: the rev edit above shifted positions, so bindings2's
    -- nodes (including any hash binding within them) are no longer valid.
    local call3, relocate_err2 = relocate_call(bufnr, ns, mark_id)
    if not call3 then
      vim.notify(relocate_err2, vim.log.levels.ERROR)
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      return
    end
    local bindings3 = get_bindings(call3, bufnr)
    if not set_attr(bufnr, call3, bindings3, hash_key or "hash", nix_string_literal(hash)) then
      vim.notify("Couldn't find an anchor to insert the hash attribute", vim.log.levels.ERROR)
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      return
    end

    reformat_and_notify(bufnr, ns, mark_id, "rev and hash")
  end)
end

return M
