local lspconfig = require('lspconfig')

lspconfig.pyright.setup {
  cmd = { pyright_binary, '--stdio' },
}
lspconfig.rnix.setup {
  cmd = { rnix_binary },
}
