{ helpers, lib, ... }:
{
  config = {
    plugins = {
      luasnip = {
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
                local function expand_skeleton()
                  local snips = require("luasnip").get_snippets()[vim.bo.ft]
                  if snips then
                    for _, snip in ipairs(snips) do
                      if snip["name"] == "_skel" then
                        require("luasnip").snip_expand(snip)
                      end
                    end
                    return true
                  else
                    vim.defer(expand_skeleton, 50)
                  end
                end
                vim.schedule(expand_skeleton)
              end
            '';
      }
    ];

  };
}
