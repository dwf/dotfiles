-- Native (vim.lsp.completion) replacement for nvim-cmp's nvim_lsp source.
local M = {}

-- Neovim only autotriggers on server-declared triggerCharacters; extend that
-- set to every alphanumeric so completion pops up on each keystroke, the
-- way cmp's autoEnableSources did.
local function with_alnum_triggers(existing)
  local set = {}
  for _, char in ipairs(existing or {}) do
    set[char] = true
  end
  for byte = 48, 57 do
    set[string.char(byte)] = true
  end
  for byte = 65, 90 do
    set[string.char(byte)] = true
  end
  for byte = 97, 122 do
    set[string.char(byte)] = true
  end
  set["_"] = true
  local chars = {}
  for char in pairs(set) do
    table.insert(chars, char)
  end
  return chars
end

-- lspkind.nvim exposes symbolic() standalone, independent of cmp, so the
-- native popup menu can keep its kind icons.
local function convert(item)
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind] or "Text"
  local icon = require("lspkind").symbolic(kind, { mode = "symbol" })
  return { kind = (icon and icon ~= "") and (icon .. " " .. kind) or kind }
end

function M.on_attach(client, bufnr)
  if not client.server_capabilities.completionProvider then
    return
  end
  client.server_capabilities.completionProvider.triggerCharacters =
    with_alnum_triggers(client.server_capabilities.completionProvider.triggerCharacters)
  vim.lsp.completion.enable(true, client.id, bufnr, {
    autotrigger = true,
    convert = convert,
  })
end

return M
