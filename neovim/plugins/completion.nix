{ config, lib, ... }:
let
  helpers = lib.nixvim;
  # Tab falls back to snippet expand/jump only if luasnip is actually enabled.
  luasnipFallback =
    if config.plugins.luasnip.enable then
      "luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>'"
    else
      "'<Tab>'";
in
{
  config = {
    extraFiles."lua/completion.lua".source = ../lua/completion.lua;
    opts.completeopt = "menu,menuone,noselect,popup,fuzzy";
    keymaps = [
      {
        key = "<C-Space>";
        action = helpers.mkRaw ''
          function()
            vim.lsp.completion.get()
          end
        '';
        mode = "i";
        options.desc = "Trigger completion";
      }
    ];
    extraConfigVim = # vim
      ''
        imap <silent><expr> <Tab>
              \ pumvisible() ?
              \   (complete_info(['selected']).selected == -1 ? '<C-n><C-y>' : '<C-y>') :
              \ ${luasnipFallback}
      '';
  };
}
