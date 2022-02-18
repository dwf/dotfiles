local nvim_lsp = require('lspconfig')
local configs = require('lspconfig.configs')

-- Configure LSP for Nix.
configs.rnix_lsp = {
 default_config = {
   cmd = {'${pkgs.rnix-lsp}/bin/rnix-lsp'};
   filetypes = {'nix'};
   root_dir = nvim_lsp.util.root_pattern('flake.nix');
   settings = {};
 }
}

-- Setup nvim-cmp, tell it to source completions from nvim-lsp.
local cmp = require('cmp')

cmp.setup({
  snippet = {
    expand = function(args) vim.fn["vsnip#anonymous"](args.body) end,
  },
  mapping = {
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  },
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
  })
})

