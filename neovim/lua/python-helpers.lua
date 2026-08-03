-- Adds a top-level import statement to a Python buffer -- any of the four
-- forms below -- then silently runs the LSP server's
-- `source.organizeImports` code action at that line, if one's on offer, so
-- a hand-inserted import ends up sorted into place the same as anything
-- the server would've put there itself.
--
--   local add_import = require("python-helpers").add_import
--   add_import(0, { name = "foo" })                                  -- import foo
--   add_import(0, { name = "foo", alias = "bar" })                   -- import foo as bar
--   add_import(0, { source = "foo", name = "bar" })                  -- from foo import bar
--   add_import(0, { source = "foo", name = "bar", alias = "baz" })   -- from foo import bar as baz
--
-- Idempotent: a spec that exactly matches (same source/name/alias) an
-- existing top-level import is a no-op. Note this is a *syntactic* check --
-- `import foo as bar` and `import foo as baz` both add, since they bind
-- different local names, even though only one `foo` import is "needed".

local M = {}

local function is_docstring_statement(node)
  if node:type() ~= "expression_statement" or node:named_child_count() ~= 1 then
    return false
  end
  return node:named_child(0):type() == "string"
end

-- Where a new top-level import should be appended: right after the last
-- existing top-level import, if there is one; otherwise right after any
-- leading comments (shebang, encoding line, ...) and the module docstring,
-- whichever of those are present. Returns a 0-indexed line number.
local function import_placement(root)
  local leading_end = 0
  local last_import_end = nil
  local past_leading = false
  for child in root:iter_children() do
    local t = child:type()
    if t == "import_statement" or t == "import_from_statement" then
      local _, _, end_row = child:range()
      last_import_end = end_row + 1
      past_leading = true
    elseif not past_leading and (t == "comment" or is_docstring_statement(child)) then
      local _, _, end_row = child:range()
      leading_end = end_row + 1
    else
      past_leading = true
    end
  end
  return last_import_end or leading_end
end

-- Every name bound by a single `import`/`from ... import` statement, as a
-- flat list of { source, name, alias } specs -- one entry per
-- comma-separated name, since `import a, b as c` and
-- `from x import a, b as c` each bind more than one name at once.
-- Wildcard (`from x import *`) and relative (`from . import x`) imports
-- contribute no comparable entries (the latter's `source` is just whatever
-- text precedes `import`, e.g. ".", so it can never accidentally match a
-- plain dotted-name spec).
local function parse_top_level_imports(bufnr, root)
  local imports = {}
  local function add(source, name_node)
    if name_node:type() == "aliased_import" then
      table.insert(imports, {
        source = source,
        name = vim.treesitter.get_node_text(name_node:field("name")[1], bufnr),
        alias = vim.treesitter.get_node_text(name_node:field("alias")[1], bufnr),
      })
    else
      table.insert(imports, { source = source, name = vim.treesitter.get_node_text(name_node, bufnr) })
    end
  end
  for child in root:iter_children() do
    local t = child:type()
    if t == "import_statement" then
      for _, name_node in ipairs(child:field("name")) do
        add(nil, name_node)
      end
    elseif t == "import_from_statement" then
      local module_name = child:field("module_name")[1]
      local source = module_name and vim.treesitter.get_node_text(module_name, bufnr)
      for _, name_node in ipairs(child:field("name")) do
        add(source, name_node)
      end
    end
  end
  return imports
end

local function import_exists(imports, spec)
  for _, existing in ipairs(imports) do
    if existing.source == spec.source and existing.name == spec.name and existing.alias == spec.alias then
      return true
    end
  end
  return false
end

local function render_import(spec)
  if spec.source then
    if spec.alias then
      return string.format("from %s import %s as %s", spec.source, spec.name, spec.alias)
    end
    return string.format("from %s import %s", spec.source, spec.name)
  end
  if spec.alias then
    return string.format("import %s as %s", spec.name, spec.alias)
  end
  return string.format("import %s", spec.name)
end

-- Applies a code action, resolving it first if the client supports
-- `codeAction/resolve` and the action doesn't already carry both an edit
-- and a command (mirrors vim.lsp.buf.code_action's own apply logic, since
-- that function can't be reused directly -- it always targets the current
-- buffer/window rather than an explicit bufnr).
local function apply_code_action(bufnr, client, action)
  local function apply(resolved)
    if resolved.edit then
      vim.lsp.util.apply_workspace_edit(resolved.edit, client.offset_encoding)
    end
    if resolved.command then
      local command = type(resolved.command) == "table" and resolved.command or resolved
      client:exec_cmd(command, { bufnr = bufnr })
    end
  end

  if not (action.edit and action.command) and client:supports_method("codeAction/resolve") then
    client:request("codeAction/resolve", action, function(err, resolved)
      apply(err and action or resolved)
    end, bufnr)
  else
    apply(action)
  end
end

-- Silently applies the first `source.organizeImports` action offered at
-- `line` (0-indexed), if any attached client has one. No-op (no error, no
-- notify) if no client supports code actions, or none offers this one.
local function organize_imports(bufnr, line)
  if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" }) == 0 then
    return
  end
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = line, character = 0 },
      ["end"] = { line = line, character = 0 },
    },
    context = { diagnostics = {}, only = { "source.organizeImports" } },
  }
  vim.lsp.buf_request_all(bufnr, "textDocument/codeAction", params, function(results)
    for client_id, result in pairs(results) do
      local action = result.result and result.result[1]
      if action then
        apply_code_action(bufnr, vim.lsp.get_client_by_id(client_id), action)
        return
      end
    end
  end)
end

-- Adds the import described by `spec` (see module comment for its shape)
-- as a new top-level statement in `bufnr` (default current buffer), unless
-- an identical import is already there, then runs `organize_imports` at
-- the line it landed on. Returns true if a statement was added.
function M.add_import(bufnr, spec)
  bufnr = bufnr or 0
  local root = vim.treesitter.get_parser(bufnr, "python"):parse()[1]:root()
  if import_exists(parse_top_level_imports(bufnr, root), spec) then
    return false
  end

  local line = import_placement(root)
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { render_import(spec) })
  organize_imports(bufnr, line)
  return true
end

return M
