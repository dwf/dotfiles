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
    keymaps =
      let
        terminal = {
          action = helpers.mkRaw ''
            function()
              require('snacks').terminal(
                nil,
                { win = {wo = { winbar = "" }}}  -- No title
              )
            end
          '';
          options.desc = "Toggle terminal";
          mode = [
            "n"
            "v"
            "t"
            "i"
          ];
        };
      in
      [
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
        {
          key = "<leader>w";
          action = helpers.mkRaw ''
            function()
              require('snacks').picker.grep_word({
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
            desc = "Grep for word under cursor";
          };
        }
        {
          key = "<leader>e";
          action = helpers.mkRaw ''
            function()
              require('snacks').picker.explorer()
            end
          '';
          options = {
            desc = "File explorer";
          };
        }
        (terminal // { key = "<C-`>"; })
        (terminal // { key = "<C-Del>"; })
      ];
  };
}
