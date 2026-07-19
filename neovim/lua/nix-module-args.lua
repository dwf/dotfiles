local M = {}

local function node_text(node, bufnr)
  return vim.treesitter.get_node_text(node, bufnr)
end

local function is_attrset(node)
  local t = node and node:type()
  return t == "attrset_expression" or t == "rec_attrset_expression"
end

-- Walks from the buffer's single top-level expression down through any
-- chain of function/let/with layers (arbitrarily nested/interleaved),
-- returning:
--   top: the very first node, before any descent — where a brand new
--        function header needs to be inserted, if none exists yet.
--   last_fn: the innermost function_expression encountered (nil if none).
--   terminal: whatever's left once none of function/let/with match, i.e.
--             the thing actually being returned once everything is
--             unwrapped (ideally an attrset).
local function walk(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "nix")
  if not ok then
    return nil
  end
  local top = parser:parse()[1]:root():field("expression")[1]
  if not top then
    return nil
  end
  local last_fn = nil
  local node = top
  while node do
    local t = node:type()
    if t == "function_expression" then
      last_fn = node
      node = node:field("body")[1]
    elseif t == "let_expression" or t == "with_expression" then
      node = node:field("body")[1]
    else
      break
    end
  end
  return { top = top, last_fn = last_fn, terminal = node }
end

-- Inserts `symbol` into `formals` (a function_expression's `formals` node)
-- as a new parameter, preserving a trailing `...` if present (formal
-- arguments must come before it). Returns true if inserted, false if
-- `symbol` was already a parameter.
local function add_formal(bufnr, formals, symbol)
  local ellipses, last_formal, open_brace
  for child in formals:iter_children() do
    local t = child:type()
    if t == "formal" then
      local name_node = child:field("name")[1]
      if name_node and node_text(name_node, bufnr) == symbol then
        return false
      end
      last_formal = child
    elseif t == "ellipses" then
      ellipses = child
    elseif t == "{" then
      open_brace = child
    end
  end
  if ellipses then
    local sr, sc = ellipses:range()
    vim.api.nvim_buf_set_text(bufnr, sr, sc, sr, sc, { symbol .. ", " })
  elseif last_formal then
    local _, _, er, ec = last_formal:range()
    vim.api.nvim_buf_set_text(bufnr, er, ec, er, ec, { ", " .. symbol })
  else
    -- Empty formals (`{ }:`): insert right after the opening brace.
    local _, _, er, ec = open_brace:range()
    vim.api.nvim_buf_set_text(bufnr, er, ec, er, ec, { symbol })
  end
  return true
end

-- Ensures `symbol` (e.g. "pkgs", "lib") is available as a function
-- parameter for this file's top-level expression, which may be wrapped in
-- any nesting/order of `let`/`with` and curried functions:
--
--   - If a function already wraps the (eventual) body, `symbol` is added
--     to the *innermost* function's formals — e.g. for
--     `{ a, ... }: { b, ... }: body`, it's `{ b, ... }` that gets the new
--     parameter, not the outer `{ a, ... }`.
--   - Otherwise, if the top-level expression is a plain attrset (optionally
--     wrapped in let/with), a brand new `{ symbol, ... }:` header is
--     inserted at the very top of the file.
--
-- Does nothing (idempotent) if `symbol` is already a parameter of the
-- target function. Reformats the buffer afterward via conform.
function M.ensure_arg(bufnr, symbol)
  bufnr = bufnr or 0
  local w = walk(bufnr)
  if not w then
    vim.notify("Buffer doesn't parse to a single top-level expression", vim.log.levels.WARN)
    return
  end

  local range
  local ns = vim.api.nvim_create_namespace("nix_module_args")

  if w.last_fn then
    local formals = w.last_fn:field("formals")[1]
    if not formals then
      vim.notify(
        "Innermost function takes a bare identifier argument, not an attrset pattern; can't add a named parameter to it",
        vim.log.levels.WARN
      )
      return
    end

    -- Anchor on the formals node itself so the reformat range grows to
    -- cover the inserted text, wherever add_formal put it.
    local fs_row, fs_col, fe_row, fe_col = formals:range()
    local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, fs_row, fs_col, { end_row = fe_row, end_col = fe_col })

    if not add_formal(bufnr, formals, symbol) then
      vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
      vim.notify(string.format("`%s` is already a parameter", symbol), vim.log.levels.INFO)
      return
    end

    local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, ns, mark_id, { details = true })
    vim.api.nvim_buf_del_extmark(bufnr, ns, mark_id)
    range = {
      ["start"] = { mark[1] + 1, mark[2] },
      ["end"] = { mark[3].end_row + 1, mark[3].end_col },
    }
  else
    if not is_attrset(w.terminal) then
      vim.notify(
        "Top-level expression isn't an attrset (optionally wrapped in let/with); not adding a function header",
        vim.log.levels.WARN
      )
      return
    end
    local sr, sc = w.top:range()
    local header = string.format("{ %s, ... }:", symbol)
    vim.api.nvim_buf_set_text(bufnr, sr, sc, sr, sc, { header, "" })
    -- No extmark needed: this is the very first insertion in the buffer,
    -- so its resulting position is already known exactly.
    range = {
      ["start"] = { sr + 1, sc },
      ["end"] = { sr + 1, sc + #header },
    }
  end

  require("lz.n").trigger_load("conform.nvim")
  require("conform").format({ bufnr = bufnr, async = true, range = range }, function(err)
    if err then
      vim.notify("Added parameter, but formatting failed: " .. err, vim.log.levels.WARN)
    else
      vim.notify(string.format("Added `%s` parameter", symbol), vim.log.levels.INFO)
    end
  end)
end

return M
