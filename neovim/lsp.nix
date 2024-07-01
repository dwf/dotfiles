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
      diagnostic = {
        "]d" = "goto_next";
        "[d" = "goto_prev";
      };
    };
    servers = {
      bashls.enable = true;
      pyright.enable = true;
      nil-ls.enable = true;
    };
  };
}
