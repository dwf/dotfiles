{
  config.plugins.nvim-cmp = {
    enable = true;
    autoEnableSources = true;
    sources = [
      { name = "nvim_lsp"; }
      { name = "path"; }
      { name = "lua"; }
      {
        name = "buffer";
        option.keyword_length = 5;
      }
    ];
    mapping = {
      "<CR>" = "cmp.mapping.confirm({ select = false })";
      "<C-Space>" = "cmp.mapping.confirm({ select = true })";
      "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
      "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
      "<S-Tab>" = "cmp.mapping.complete()";
      "<Esc>" = "cmp.mapping.close()";
    };
    preselect = "None";
    experimental = {
      native_menu = false;
      ghost_text = true;
    };
  };
}
