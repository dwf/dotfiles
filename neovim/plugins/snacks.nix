{ helpers, ... }:
{
  config = {
    plugins.snacks = {
      enable = true;
      settings = {
        input.enabled = true;
        notifier.enabled = true;
        picker.enabled = true;

        # Roughly mimic dressing.nvim
        styles.input = {
          relative = "cursor";
          row = -3;
          col = 0;
        };
      };
    };
    keymaps = [
      {
        key = "<C-p>";
        action = helpers.mkRaw ''
          function()
            require('snacks').picker.smart({
              layout = { preset = "telescope" },
              win = {
                input = {
                  keys = {
                    -- Remap Esc to close the picker, even in insert mode
                    ["<Esc>"] = { "close", mode = { "n", "i" } }
                  }
                }
              }
            })
          end
        '';
        options = {
          desc = "Smart file picker";
        };
      }
    ];
  };
}
