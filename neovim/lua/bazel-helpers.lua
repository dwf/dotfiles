-- Adds/removes a single label from a rule's `deps` list in a Bazel BUILD
-- file, driven purely by a file path (not a live buffer) since these are
-- meant for scripted/one-shot use rather than interactive editing:
--
--   require("bazel-helpers").add_dep({
--     path = "path/to/BUILD",
--     target = "my_target",
--     dep = "//some/other:label",
--     ignore = false,
--   })
--
-- Both functions hard-error (via `error()`) if the BUILD file or the named
-- rule can't be found, or if the rule's `deps` isn't a plain list literal
-- (e.g. built via `select()` or `+`) -- there's no safe way to edit those.
-- Whether a redundant add/remove (dep already present / already absent) is
-- silent or produces a `vim.notify` warning is controlled by `opts.ignore`.
-- On any actual change, the file is written back to disk.

local M = {}

local function node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

local function get_indent(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  return line:match("^%s*")
end

local function starlark_string_literal(s)
  return '"' .. s:gsub('[\\"]', "\\%0") .. '"'
end

-- Extracts the literal text of a `string` node (its `string_content`), or
-- nil if `node` isn't a plain string (e.g. missing/some other expression).
local function string_value(node, bufnr)
  if not node or node:type() ~= "string" then
    return nil
  end
  for child in node:iter_children() do
    if child:type() == "string_content" then
      return node_text(child, bufnr)
    end
  end
  return ""
end

local function all_children(node)
  local out = {}
  for child in node:iter_children() do
    out[#out + 1] = child
  end
  return out
end

-- Maps keyword-argument name -> { kwarg = <keyword_argument node>, value =
-- <its value node> } for a `call` node's arguments. Positional arguments
-- are ignored -- Bazel rules only take keyword arguments.
local function get_kwargs(call, bufnr)
  local arglist = call:field("arguments")[1]
  if not arglist then
    return nil
  end
  local kwargs = {}
  for child in arglist:iter_children() do
    if child:type() == "keyword_argument" then
      local name_node = child:field("name")[1]
      if name_node then
        kwargs[node_text(name_node, bufnr)] = { kwarg = child, value = child:field("value")[1] }
      end
    end
  end
  return kwargs, arglist
end

-- Finds the (first) `call` anywhere in the file with a `name = "target"`
-- keyword argument. Doesn't restrict to top-level calls, so this also finds
-- rules wrapped in a macro invocation, as long as the macro itself forwards
-- `name` as a plain string literal keyword argument.
local function find_rule_call(bufnr, target)
  local root = vim.treesitter.get_parser(bufnr, "starlark"):parse()[1]:root()
  local query = vim.treesitter.query.parse("starlark", "(call) @call")
  for _, call in query:iter_captures(root, bufnr) do
    local kwargs = get_kwargs(call, bufnr)
    local name_kw = kwargs and kwargs.name
    if name_kw and string_value(name_kw.value, bufnr) == target then
      return call
    end
  end
  return nil
end

local function find_string_entry(bufnr, list_node, value)
  for child in list_node:iter_children() do
    if child:type() == "string" and string_value(child, bufnr) == value then
      return child
    end
  end
  return nil
end

-- Appends `rendered_item` as a new comma-separated element of `container`
-- (a `list` or `argument_list` node -- both are just "bracket, comma
-- -separated children, bracket"), matching whatever single-line/multi-line
-- style and indentation the container already uses. `open_type`/
-- `close_type` are the container's bracket node types.
local function append_list_item(bufnr, container, open_type, close_type, rendered_item)
  local children = all_children(container)
  local open, close, items = nil, nil, {}
  for _, c in ipairs(children) do
    local t = c:type()
    if t == open_type then
      open = c
    elseif t == close_type then
      close = c
    elseif t ~= "," then
      items[#items + 1] = c
    end
  end

  local start_row, _, end_row, _ = container:range()
  local multiline = start_row ~= end_row

  if #items == 0 then
    -- Empty container: always inline, even if it was originally written
    -- spanning multiple lines (e.g. `deps = [\n],`) -- there's no existing
    -- entry to match a multi-line style against, so collapsing it down to
    -- a single line is the least surprising result.
    local _, _, or_row, or_col = open:range()
    local cr_row, cr_col = close:range()
    vim.api.nvim_buf_set_text(bufnr, or_row, or_col, cr_row, cr_col, { rendered_item })
    return
  end

  local last = items[#items]
  local last_idx
  for i, c in ipairs(children) do
    if c == last then
      last_idx = i
      break
    end
  end
  local trailing_comma = children[last_idx + 1] and children[last_idx + 1]:type() == ","

  if multiline then
    local indent = get_indent(bufnr, (last:range()))
    local new_line = indent .. rendered_item .. ","
    if trailing_comma then
      local _, _, cr, cc = children[last_idx + 1]:range()
      vim.api.nvim_buf_set_text(bufnr, cr, cc, cr, cc, { "", new_line })
    else
      local _, _, lr, lc = last:range()
      vim.api.nvim_buf_set_text(bufnr, lr, lc, lr, lc, { ",", new_line })
    end
  else
    if trailing_comma then
      local _, _, cr, cc = children[last_idx + 1]:range()
      vim.api.nvim_buf_set_text(bufnr, cr, cc, cr, cc, { " " .. rendered_item .. "," })
    else
      local _, _, lr, lc = last:range()
      vim.api.nvim_buf_set_text(bufnr, lr, lc, lr, lc, { ", " .. rendered_item })
    end
  end
end

-- Removes `entry` (one of `list_node`'s children) along with exactly one
-- adjacent comma -- whichever separator actually belongs to it, so
-- removing the first, a middle, or the last (possibly trailing-comma'd)
-- element all leave the remaining elements correctly comma-separated.
local function remove_list_entry(bufnr, list_node, entry)
  local children = all_children(list_node)
  local idx
  for i, c in ipairs(children) do
    if c == entry then
      idx = i
      break
    end
  end
  local prev, nxt = children[idx - 1], children[idx + 1]

  local from_row, from_col, to_row, to_col
  if nxt and nxt:type() == "," then
    local _, _, fr, fc = prev:range()
    local _, _, tr, tc = nxt:range()
    from_row, from_col, to_row, to_col = fr, fc, tr, tc
  elseif prev and prev:type() == "," then
    local pprev = children[idx - 2]
    local _, _, fr, fc = pprev:range()
    local _, _, tr, tc = entry:range()
    from_row, from_col, to_row, to_col = fr, fc, tr, tc
  else
    from_row, from_col, to_row, to_col = entry:range()
  end

  vim.api.nvim_buf_set_text(bufnr, from_row, from_col, to_row, to_col, { "" })
end

-- Loads `path` into a buffer (hard error if it doesn't exist) and locates
-- `target`'s rule call in it (hard error if not found). Returns
-- bufnr, call, kwargs, arglist.
local function load_and_find_rule(path, target)
  if vim.fn.filereadable(path) ~= 1 then
    error(string.format("BUILD file not found: %s", path))
  end
  local bufnr = vim.fn.bufadd(path)
  vim.fn.bufload(bufnr)

  local call = find_rule_call(bufnr, target)
  if not call then
    error(string.format("No rule named %q found in %s", target, path))
  end
  local kwargs, arglist = get_kwargs(call, bufnr)
  return bufnr, call, kwargs, arglist
end

local function save(bufnr)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd("write")
  end)
end

-- Adds `opts.dep` to `opts.target`'s `deps` in the BUILD file at
-- `opts.path`, creating the `deps` argument if the rule doesn't have one
-- yet. If `opts.dep` is already present: silently does nothing when
-- `opts.ignore` is true, otherwise emits a `vim.notify` warning. Returns
-- true if the file was changed.
function M.add_dep(opts)
  local bufnr, _, kwargs, arglist = load_and_find_rule(opts.path, opts.target)
  local literal = starlark_string_literal(opts.dep)

  local deps_kw = kwargs.deps
  if deps_kw then
    if deps_kw.value:type() ~= "list" then
      error(string.format("`deps` of %q in %s isn't a plain list literal", opts.target, opts.path))
    end
    if find_string_entry(bufnr, deps_kw.value, opts.dep) then
      if not opts.ignore then
        vim.notify(
          string.format("`%s` is already in deps of %q; not adding", opts.dep, opts.target),
          vim.log.levels.WARN
        )
      end
      return false
    end
    append_list_item(bufnr, deps_kw.value, "[", "]", literal)
  else
    append_list_item(bufnr, arglist, "(", ")", "deps = [" .. literal .. "]")
  end

  save(bufnr)
  return true
end

-- Removes `opts.dep` from `opts.target`'s `deps` in the BUILD file at
-- `opts.path`. If it isn't there (or the rule has no `deps` at all):
-- silently does nothing when `opts.ignore` is true, otherwise emits a
-- `vim.notify` warning. Returns true if the file was changed.
function M.remove_dep(opts)
  local bufnr, _, kwargs = load_and_find_rule(opts.path, opts.target)

  local deps_kw = kwargs.deps
  local entry = deps_kw and deps_kw.value:type() == "list" and find_string_entry(bufnr, deps_kw.value, opts.dep)
  if deps_kw and deps_kw.value:type() ~= "list" then
    error(string.format("`deps` of %q in %s isn't a plain list literal", opts.target, opts.path))
  end
  if not entry then
    if not opts.ignore then
      vim.notify(string.format("`%s` isn't in deps of %q; not removing", opts.dep, opts.target), vim.log.levels.WARN)
    end
    return false
  end

  remove_list_entry(bufnr, deps_kw.value, entry)
  save(bufnr)
  return true
end

return M
