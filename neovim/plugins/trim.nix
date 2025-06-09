{ pkgs, lib, ... }:
{
  config.plugins.trim = {
    enable = true;
    package = pkgs.vimPlugins.trim-nvim.overrideAttrs (_: {
      version = "2025-05-17";
      src = pkgs.fetchFromGitHub {
        owner = "cappyzawa";
        repo = "trim.nvim";
        rev = "d0760a840ca2fe4958353dee567a90c2994e70a7";
        sha256 = "sha256-CZwIa9GccHS/nZ+lq27A6NfpBCqEHOrTC7Hd7skPwnc=";
      };
      patches = [
        (pkgs.writeText "terminal-whitespace-fix.patch" ''
          diff --git a/lua/trim/highlighter.lua b/lua/trim/highlighter.lua
          index 39bb9dc..c102b6c 100644
          --- a/lua/trim/highlighter.lua
          +++ b/lua/trim/highlighter.lua
          @@ -56,7 +56,7 @@ function highlighter.setup()
             })

             local augroup = vim.api.nvim_create_augroup('TrimHighlight', { clear = true })
          -  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'TermEnter' }, {
          +  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter', 'TermEnter', 'TermOpen' }, {
               group = augroup,
               callback = function()
                 if (vim.bo.buftype == ''' or vim.bo.buftype == "quickfix") and not has_value(config.ft_blocklist, vim.bo.filetype) then
        '')
      ];
    });
    lazyLoad.settings.event = "DeferredUIEnter";
    settings = {
      ft_blocklist = [
        "diff"
        "hgcommit"
        "gitcommit"
        "qf"
      ];
      highlight = true;
    };
  };
}
