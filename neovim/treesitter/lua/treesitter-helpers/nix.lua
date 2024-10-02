local M = {}

function M.maybe_add_module_import(bufnr, name)
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

return M
