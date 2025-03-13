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
        vim.api.nvim_command("augroup LSP")
        vim.api.nvim_command("autocmd!")
        if client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_command("autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()")
          vim.api.nvim_command("autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()")
          vim.api.nvim_command("autocmd CursorMoved <buffer> lua vim.lsp.util.buf_clear_references()")
        end
        vim.api.nvim_command("augroup END")
      '';
    servers = {
      arduino_language_server.enable = true;
      bashls.enable = true;
      pyright.enable = true;
      nil_ls = {
        enable = true;
        settings.diagnostics.ignored = [ "unused_binding" ]; # handled by deadnix
      };
      lua_ls = {
        enable = true;
        settings = {
          diagnostics.globals = [ "vim" ];
          runtime.version = "Lua 5.1";
        };
      };
    };
  };
}
