{ lib, ... }:
{
  config = {
    plugins = {
      luasnip = {
        enable = true;
        extraConfig.enable_autosnippets = true;
        fromLua = [ { paths = ./snippets; } ];
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

  };
}
