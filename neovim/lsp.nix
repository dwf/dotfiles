{
  config.plugins.lsp = {
    enable = true;
    keymaps = {
      diagnostic = {
        "]d" = "goto_next";
        "[d" = "goto_prev";
      };
      lspBuf = {
        "<Leader>rn" = "rename";
        "<Leader>ca" = "code_action";
        "<C-k>" = "signature_help";
        K = "hover";
        g0 = "document_symbol";
        gW = "workspace_symbol";
        gd = "definition";
        gD = "declaration";
        gi = "implementation";
        gr = "references";
        gt = "type_definition";
      };
    };
    onAttach = # lua
      ''
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
        if vim.lsp.formatexpr then
          vim.api.nvim_buf_set_option(bufnr, "formatexpr", "v:lua.vim.lsp.formatexpr")
        end
        if vim.lsp.tagfunc then
          vim.api.nvim_buf_set_option(bufnr, "tagfunc", "v:lua.vim.lsp.tagfunc")
        end
        vim.api.nvim_command("augroup LSP")
        vim.api.nvim_command("autocmd!")
        if client.server_capabilities.documentFormattingProvider then
          vim.api.nvim_command("autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()")
          vim.api.nvim_command("autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()")
          vim.api.nvim_command("autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()")
        end
        vim.api.nvim_command("augroup END")
      '';
    servers = {
      bashls.enable = true;
      pyright.enable = true;
      nil-ls.enable = true;
      lua-ls = {
        enable = true;
        settings = {
          diagnostics.globals = [ "vim" ];
          runtime.version = "Lua 5.1";
        };
      };
    };
  };
}
