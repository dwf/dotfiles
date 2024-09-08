{ helpers, ... }:
{
  config.plugins.telescope = {
    enable = true;
    keymaps = {
      "<C-p>" = {
        action = "find_files";
        options = {
          silent = true;
          desc = "Telescope: find files";
        };
      };
    };
    settings.defaults.mappings = {
      i."<Esc>" = helpers.mkRaw "require('telescope.actions').close";
    };
  };
}
