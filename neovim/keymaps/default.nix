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
              -- Priority 1: luasnip, if the node under the cursor can expand
              -- or jump. pcall since luasnip is lazy-loaded (see
              -- ../plugins/luasnip.nix) and may not be require()d yet.
              -- Deferred (vim.schedule), like the blink-edit branch below:
              -- this whole function runs during expr-mapping evaluation,
              -- and expand_or_jump()'s cursor/extmark movement doesn't
              -- reliably take effect when called synchronously from there
              -- (jumpable() true, jump silently doesn't move the cursor).
              local ok_luasnip, luasnip = pcall(require, "luasnip")
              if ok_luasnip and luasnip.expand_or_jumpable() then
                vim.schedule(function()
                  luasnip.expand_or_jump()
                end)
                return ""
              end

              -- Priority 2: Neovim's native LSP inline completion (e.g.
              -- Copilot's LSP, see :help vim.lsp.inline_completion) -- not
              -- wired to any client in this tree today, so get() harmlessly
              -- returns false until/unless one is. get() itself schedules
              -- the buffer edit but returns synchronously whether there was
              -- a candidate to accept.
              if vim.lsp.inline_completion.get() then
                return ""
              end

              -- Priority 3: blink-edit next-edit-suggestion (see
              -- ../plugins/blink-edit.nix). pcall since it's lazy-loaded and
              -- may not exist at all on hosts without a llama-nes backend;
              -- vim.g.blink_edit_enabled check mirrors blink-edit's own
              -- internal toggle guard so a `:lua require('blink-edit').toggle()`
              -- off-state falls straight through to regular completion.
              local ok_blink, blink_edit = pcall(require, "blink-edit")
              if ok_blink and vim.g.blink_edit_enabled ~= false and blink_edit.has_prediction() then
                vim.schedule(function()
                  blink_edit.accept()
                end)
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
        desc = "Insert suggestion: luasnip > LSP inline completion > blink-edit > completion > literal tab";
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
