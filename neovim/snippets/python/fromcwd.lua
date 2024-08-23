-- Path-based module expansion when file exists under a path prefix.
local ls = require("luasnip")
local f = ls.function_node
local s = ls.snippet
local t = ls.text_node
local c = require("luasnip.extras.conditions")
local ce = require("luasnip.extras.conditions.expand")
local empty_line = ce.line_begin * ce.line_end
local prefix = vim.g.fromcwd_snippet_prefix

local module_from_path_suffix = function(path)
  return path:gsub("^" .. prefix .. "/[^/]+/", ""):match("(.*)/"):gsub("/", ".")
end

local cwd_under_prefix = function()
  local filename = vim.api.nvim_buf_get_name(0)
  local prefix_present = filename:sub(1, #prefix) == prefix
  if prefix_present then
    local _, slash_count = filename:sub(#prefix + 2, -1):gsub("/", "")
    return slash_count > 1 -- we must be at least one directory below prefix
  end
end

local autosnippets = {}

if prefix ~= nil then
  assert(prefix:sub(-1, -1) ~= "/", "no trailing / expected")
  autosnippets[#autosnippets + 1] = s({
    trig = "fromcwd",
    desc = "Path-based CWD module expansion.",
  }, {
    t("from "),
    f(function()
      return module_from_path_suffix(vim.api.nvim_buf_get_name(0))
    end, {}),
    t(" import "),
  }, {
    condition = empty_line * c.make_condition(cwd_under_prefix, {}),
  })
end

return {}, autosnippets
