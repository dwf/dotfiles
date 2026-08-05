{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  imports = [
    ./nix.nix
  ];

  config.keymaps = [
    {
      key = "<Tab>";
      mode = "i";
      action =
        helpers.mkRaw # lua
          ''
            function()
              -- Tries whichever ghost-text-style suggestion (native LSP
              -- inline completion, blink-edit next-edit prediction) is
              -- currently showing and accepts it. Returns true if one was.
              -- pcall on blink-edit since it's lazy-loaded and may not
              -- exist at all on hosts without a llama-nes backend;
              -- vim.g.blink_edit_enabled check mirrors blink-edit's own
              -- internal toggle guard so a
              -- `:lua require('blink-edit').toggle()` off-state falls
              -- through to whatever's next. get() harmlessly returns false
              -- until/unless an inline-completion LSP client (e.g.
              -- Copilot's) is wired up -- not the case anywhere in this
              -- tree today. Deferred (vim.schedule), like luasnip's jump
              -- below: this whole outer function runs during
              -- expr-mapping evaluation, and blink_edit.accept()'s buffer
              -- edit doesn't reliably take effect when called synchronously
              -- from there.
              local function accept_ghost_text()
                if vim.lsp.inline_completion.get() then
                  return true
                end
                local ok_blink, blink_edit = pcall(require, "blink-edit")
                if ok_blink and vim.g.blink_edit_enabled ~= false and blink_edit.has_prediction() then
                  vim.schedule(function()
                    blink_edit.accept()
                  end)
                  return true
                end
                return false
              end

              -- pcall since luasnip is lazy-loaded (see
              -- ../plugins/luasnip.nix) and may not be require()d yet.
              local ok_luasnip, luasnip = pcall(require, "luasnip")

              -- Priority 1: expanding a brand-new snippet trigger is
              -- unambiguous -- there's no visible suggestion yet to
              -- arbitrate against. Deferred (vim.schedule): expand_or_jump's
              -- cursor/extmark movement doesn't reliably take effect when
              -- called synchronously from an expr-mapping.
              if ok_luasnip and luasnip.expandable() then
                vim.schedule(function()
                  luasnip.expand_or_jump()
                end)
                return ""
              end

              -- Priority 2: already inside a snippet field. Ghost text
              -- wins over jumping to the next field when one's actually
              -- visible -- accepting a suggestion you can see is what
              -- <Tab> means in that moment; jumping out from under it
              -- would silently discard it instead. Falls through to the
              -- jump (deferred for the same reason as expand_or_jump
              -- above) when nothing's showing.
              if ok_luasnip and luasnip.in_snippet() and luasnip.jumpable(1) then
                if accept_ghost_text() then
                  return ""
                end
                vim.schedule(function()
                  luasnip.jump(1)
                end)
                return ""
              end

              -- Priority 3: ghost text outside any snippet context.
              if accept_ghost_text() then
                return ""
              end

              -- Priority 4: regular completion menu -- native
              -- vim.lsp.completion popup (see ../plugins/completion.nix), no
              -- nvim-cmp involved. <C-n> first when nothing's selected yet
              -- so <C-y> has an entry to confirm, matching completion.nix's
              -- former standalone Tab mapping (now replaced by this one).
              if vim.fn.pumvisible() == 1 then
                local selected = vim.fn.complete_info({ "selected" }).selected
                return selected == -1 and "<C-n><C-y>" or "<C-y>"
              end

              -- Nothing above had anything to offer: literal tab.
              return "<Tab>"
            end
          '';
      options = {
        expr = true;
        silent = true;
        desc = "Insert suggestion: luasnip expand > (in-snippet) ghost text > luasnip jump > ghost text > completion > literal tab";
      };
    }
    {
      action = "\"hy:%s/<C-r>h//g<left><left>";
      key = "<leader>R";
      options = {
        desc = "Search and replace selection";
      };
      mode = "v";
    }
    {
      action = "\"syiw:%s/<C-r>s//g<left><left>";
      key = "<leader>R";
      options = {
        desc = "Search and replace word under cursor";
      };
      mode = "n";
    }
    {
      action = ":%s///g<left><left><left>";
      key = "<leader>r";
      options = {
        desc = "Search and replace";
      };
      mode = "n";
    }
  ];
}
