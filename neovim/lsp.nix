{
  config.plugins.lsp = {
    enable = true;
    keymaps.diagnostic = {
      "]d" = "goto_next";
      "[d" = "goto_prev";
    };
    servers = {
      bashls.enable = true;
      pyright.enable = true;
      nil-ls.enable = true;
    };
  };
}
