{
  config.plugins.cmp = {
    enable = true;
    autoEnableSources = true;
    settings = {
      sources = [
        { name = "nvim_lsp"; }
        { name = "nvim_lsp_signature_help"; }
        { name = "path"; }
        {
          name = "buffer";
          option.keyword_length = 5;
        }
      ];
      mapping = {
        "<CR>" = "cmp.mapping.confirm({ select = false })";
        "<Tab>" = "cmp.mapping.confirm({ select = true })";
        "<C-Space>" = "cmp.mapping(cmp.mapping.complete(), {'i', 'c'})";
        "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
        "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
        "<C-u>" = "cmp.mapping.scroll_docs(-4)";
        "<C-d>" = "cmp.mapping.scroll_docs(4)";
        "<C-e>" = "cmp.mapping.close()";
      };
      preselect = "cmp.PreselectMode.None";
      experimental = {
        native_menu = false;
        ghost_text = true;
      };
    };
  };
}
