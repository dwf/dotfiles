{
  config.plugins.nvim-cmp = {
    enable = true;
    autoEnableSources = true;
    sources = [
      { name = "nvim_lsp"; }
      { name = "path"; }
      { name = "lua"; }
      { name = "vsnip"; }
      {
        name = "buffer";
        option.keyword_length = 5;
      }
    ];
    mapping = {
      "<CR>" = "cmp.mapping.confirm({ select = false })";
    };
    preselect = "None";
    experimental = {
      native_menu = false;
      ghost_text = true;
    };
  };
}
