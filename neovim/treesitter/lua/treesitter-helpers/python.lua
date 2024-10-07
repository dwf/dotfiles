local M = {}

local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local function first_import_placement(bufnr, tree)
  local query = vim.treesitter.query.parse(
    "python",
    [[
      (module
        (comment)*
        . (comment)? @last-comment
        .
        (expression_statement
          (string
            (string_start)
            (string_content)
            (string_end)) @module-docstring)?)
    ]]
  )
  local line = 0
  for _, node, _, _ in query:iter_captures(tree:root(), bufnr) do
    local _, _, end_line, _ = node:range()
    line = end_line + 1
  end
  return line
end

local function parse_top_level_imports(bufnr, tree)
  local query = vim.treesitter.query.parse(
    "python",
    [[
      (module
      [
       (import_statement
         name: (dotted_name) @name @imported)
       (import_statement
         name: (aliased_import
                 name: (dotted_name) @name
                 alias: (identifier) @alias @imported))
       (import_from_statement
         module_name: (dotted_name) @source
         name: (dotted_name) @name @imported)
       (import_from_statement
         module_name: (dotted_name) @source
         name: (aliased_import
                 name: (dotted_name) @name
                 alias: (identifier) @alias @imported))
      ] @statement)
    ]]
  )
  local imports = {}
  for _, match, _ in query:iter_matches(tree:root(), bufnr) do
    local current = {}
    for id, node in pairs(match) do
      current[query.captures[id]] = node
    end
    imports[#imports + 1] = current
  end
  return imports
end

local function get_node_text(bufnr, node)
  local start_row, start_col, end_row, end_col = node:range()
  local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  return table.concat(text, "\n")
end

local function import_exists(bufnr, import_spec, parsed_imports)
  for _, nodes in ipairs(parsed_imports) do
    local imported = import_spec.name
    if import_spec.alias ~= nil then
      imported = import_spec.alias
    end
    if nodes.imported ~= nil and imported == get_node_text(bufnr, nodes.imported) then
      return true
    end
  end
  return false
end

local function render_import(spec)
  if spec.source ~= nil then
    if spec.alias ~= nil then
      return string.format("from %s import %s as %s", spec.source, spec.name, spec.alias)
    else
      return string.format("from %s import %s", spec.source, spec.name)
    end
  else
    if spec.alias ~= nil then
      return string.format("import %s as %s", spec.name, spec.alias)
    else
      return string.format("import %s", spec.name)
    end
  end
end

function M.import_placement(bufnr, tree, parsed_imports, placement_opts)
  if parsed_imports == nil then
    parsed_imports = parse_top_level_imports(bufnr, tree)
  end
  if #parsed_imports == 0 then
    return first_import_placement(bufnr, tree)
  end
  local _, _, last_line, _ = parsed_imports[#parsed_imports].statement:range()
  local after_last = last_line + 1
  local cache = {}
  if placement_opts == nil then
    placement_opts = {}
  end
  for _, import_nodes in ipairs(parsed_imports) do
    cache = {}
    for _, heuristic in ipairs(placement_opts) do
      local heuristic_matches_this_import = true
      local before_after, matching = heuristic[1], heuristic[2]
      for attribute, value in pairs(matching) do
        if cache[attribute] == nil and import_nodes[attribute] ~= nil then
          cache[attribute] = get_node_text(bufnr, import_nodes[attribute])
        end
        if cache[attribute] ~= value then
          heuristic_matches_this_import = false
          break
        end
      end
      local _, _, line, _ = import_nodes.statement:range()
      if heuristic_matches_this_import then
        if before_after == "after" then
          line = line + 1
        end
        return line
      end
    end
  end
  return after_last
end

function M.maybe_add_import(bufnr, import_spec, opts)
  if opts == nil then
    opts = {}
  end
  local tree = vim.treesitter.get_parser(bufnr):parse()[1]
  local parsed_imports = parse_top_level_imports(bufnr, tree)
  if not import_exists(bufnr, import_spec, parsed_imports) then
    local lines = { render_import(import_spec) }
    local placement = M.import_placement(bufnr, tree, parsed_imports, opts.placement)
    vim.api.nvim_buf_set_lines(bufnr, placement, placement, false, lines)
  end
end

function M.insert_after_last_import(offset)
  if offset == nil then
    offset = 0
  end
  local tree = vim.treesitter.get_parser(0):parse()[1]
  local line = require("treesitter-helpers.python").import_placement(0, tree)
  vim.fn.cursor(line + offset, 0)
  vim.api.nvim_feedkeys("o", "n", false)
end

function M.expand_import_snippet(which_snippet)
  local snippets = {
    import = s({}, { t("import "), i(1, "module") }),
    from_import = s({}, { t("from "), i(1, "module"), t(" import "), i(2, "name") }),
    import_as = s({}, { t("import "), i(1, "module"), t(" as "), i(2, "alias") }),
    from_import_as = s({}, { t("from "), i(1, "module"), t(" import "), i(2, "name"), t(" as "), i(3, "alias") }),
  }
  M.insert_after_last_import(1)
  ls.snip_expand(snippets[which_snippet], {})
end

return M
