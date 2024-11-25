local M = {}

function M.maybe_add_empty_module_args(bufnr)
  local query = vim.treesitter.query.parse(
    "nix",
    [[
      (source_code
        expression: [
          (let_expression)
          (attrset_expression)
          (with_expression)
        ] @toplevel)
    ]]
  )
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local toplevel = nil
  for _, node, _, _ in query:iter_captures(tree:root(), bufnr) do
    assert(toplevel == nil)
    toplevel = node
  end
  if toplevel then
    local s_row, _, _, _ = toplevel:range()
    vim.api.nvim_buf_set_lines(bufnr, s_row, s_row, true, { "{ ... }:" })
  end
end

function M.maybe_add_module_import(bufnr, name)
  M.maybe_add_empty_module_args(bufnr)

  local query = vim.treesitter.query.parse(
    "nix",
    [[
      (source_code
        expression:
        (function_expression
          formals:
          (formals
            formal: (formal (identifier) @ident)?
            ellipses: (ellipses) @ellipses) @formals))
    ]]
  )

  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local ellipses = nil
  local formals = nil
  for _, node, _, _ in query:iter_captures(tree:root(), bufnr) do
    if node:type() == "identifier" then
      local s_r, s_c, e_r, e_c = node:range()
      local text = vim.api.nvim_buf_get_text(bufnr, s_r, s_c, e_r, e_c, {})[1]
      if text == name then
        return false
      end
    elseif node:type() == "ellipses" then
      ellipses = node
    elseif node:type() == "formals" then
      formals = node
    end
  end
  if ellipses ~= nil then
    local i_row, i_col, _, _ = ellipses:range()
    local new_text = { name .. ", " }
    vim.api.nvim_buf_set_text(bufnr, i_row, i_col, i_row, i_col, new_text)
    assert(formals ~= nil)
    local f_r, f_c, f_re, f_ce = formals:range()
    require("conform").format({
      bufnr = bufnr,
      async = true,
      range = {
        ["start"] = { f_r + 1, f_c },
        ["end"] = { f_re + 1, f_ce },
      },
    })
  end
end

function M.maybe_remove_empty_module_args(bufnr)
  -- Match a top-level function expression.
  local query = vim.treesitter.query.parse(
    "nix",
    [[
      (source_code
        (function_expression
          formals:
            (formals
              ellipses: (_)) @formals
          body: (_) @body) @func)
    ]]
  )
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local nodes = {}
  -- Unpack the captures into a lua table indexed by capture group.
  for id, node, _, _ in query:iter_captures(tree:root(), bufnr) do
    local capture = query.captures[id]
    -- We expect at most one capture of each type.
    assert(nodes[capture] == nil)
    nodes[capture] = node
  end
  if nodes.formals then
    for _, name in nodes.formals:iter_children() do
      -- If we find any children of type "formal", we have non-ellipses
      -- arguments, and we should bail.
      if name == "formal" then
        return
      end
    end
    -- Remove everything from the beginning of the function_expression
    -- node to the beginning of its "body".
    local f_row, f_col, _, _ = nodes.func:range()
    local b_row, b_col, _, _ = nodes.body:range()
    vim.api.nvim_buf_set_text(bufnr, f_row, f_col, b_row, b_col, { "" })
  end
end

return M
