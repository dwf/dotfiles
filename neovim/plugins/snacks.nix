{ lib, pkgs, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    plugins.snacks = {
      enable = true;

      # Work around clash with nvim-treesitter
      package = pkgs.vimPlugins.snacks-nvim.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          rm -rf $out/queries
        '';
      });

      lazyLoad.settings =
        let
          terminal = {
            __unkeyed-2 = helpers.mkRaw ''
              function()
                require('snacks').terminal(
                  nil,
                  { win = {wo = { winbar = "" }}}  -- No title
                )
              end
            '';
            desc = "Toggle terminal";
            mode = [
              "n"
              "v"
              "t"
              "i"
            ];
          };
        in
        {
          event = "DeferredUIEnter";
          keys = [
            {
              __unkeyed-1 = "<C-p>";
              __unkeyed-2 = helpers.mkRaw ''
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
              desc = "Smart file picker";
            }
            {
              __unkeyed-1 = "<leader>w";
              __unkeyed-2 = helpers.mkRaw ''
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
              desc = "Grep for word under cursor";
            }
            {
              __unkeyed-1 = "<leader>e";
              __unkeyed-2 = helpers.mkRaw ''
                function()
                  require('snacks').picker.explorer()
                end
              '';
              desc = "File explorer";
            }
            {
              __unkeyed-1 = "<leader>gd";
              __unkeyed-2 = helpers.mkRaw ''
                function()
                  require('snacks').picker.git_diff()
                end
              '';
              desc = "Git diff picker";
            }
            {
              __unkeyed-1 = "<leader>N";
              __unkeyed-2 = helpers.mkRaw ''
                function()
                  require('snacks.notifier').show_history()
                end
              '';
              desc = "Show notification history";
            }
            (terminal // { __unkeyed-1 = "<C-`>"; })
            (terminal // { __unkeyed-1 = "<C-Del>"; })
          ];
        };
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
  };
}
