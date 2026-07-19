{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    plugins = {
      luasnip = {
        lazyLoad.settings.event = "DeferredUIEnter";
        enable = true;
        settings.enable_autosnippets = true;
        fromLua = [ { paths = ../snippets; } ];
      };
      cmp.settings = {
        sources = lib.mkBefore [ { name = "luasnip"; } ];
        snippet.expand = # lua
          ''
            function(args)
              require('luasnip').lsp_expand(args.body)
            end
          '';
      };
    };
    extraConfigVim = # vim
      ''
        imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>'
        " -1 for jumping backwards.
        inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>

        snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
        snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

        " For changing choices in choiceNodes (not strictly necessary for a basic setup).
        imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
        smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
      '';

    autoCmd = [
      {
        event = [ "BufNewFile" ];
        pattern = [ "*.nix" ];
        callback =
          helpers.mkRaw # lua
            ''
              function()
                -- luasnip is lazy-loaded (see lazyLoad.settings.event above),
                -- and its `fromLua` snippets are *also* lazily loaded per
                -- filetype (nixvim's default `lazyLoad = true` on the loader
                -- submodule), via a FileType autocmd luasnip registers
                -- internally. Force luasnip to load now, synchronously,
                -- *before* this buffer's own FileType event fires - BufNewFile
                -- is always followed by FileType, never the reverse, so this
                -- guarantees luasnip's own FileType hook (which populates
                -- get_snippets()) gets registered in time to catch it and
                -- fire before ours below (autocmds for one event run in
                -- registration order). Used to instead poll for readiness via
                -- vim.defer_fn on a 50ms timer, racing DeferredUIEnter (which
                -- never fires at all in headless/non-UI contexts, and could
                -- lose the race even interactively) - polling either found
                -- nothing (skeleton silently never expanded) or, with an
                -- older typo'd `vim.defer` instead of `vim.defer_fn`, threw
                -- "attempt to call a nil value" on the first retry.
                require("lz.n").trigger_load("luasnip")
                vim.api.nvim_create_autocmd("FileType", {
                  pattern = "nix",
                  once = true,
                  callback = function()
                    local snips = require("luasnip").get_snippets()["nix"]
                    if snips then
                      for _, snip in ipairs(snips) do
                        if snip["name"] == "_skel" then
                          require("luasnip").snip_expand(snip)
                        end
                      end
                    end
                  end,
                })
              end
            '';
      }
    ];

  };
}
