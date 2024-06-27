{ lib, ... }:
{
  config = {
    plugins.trouble = {
      enable = true;

      # Below this line moves under 'settings' eventually.
      settings = {
        position = "bottom";
        height = 10;
        mode = "workspace_diagnostics";
        auto_open = false;
        auto_close = true;
      };
    };

    keymaps =
      with lib;
      let
        # TODO: remove after Neovim 0.10
        navKeys =
          mapAttrsToList
            (key: suffix: {
              inherit key;
              action.__raw = "vim.diagnostic.goto_${toLower suffix}";
              options = {
                desc = "${suffix} LSP diagnostic";
                silent = true;
              };
            })
            {
              "]d" = "Next";
              "[d" = "Prev";
            };
      in
      navKeys
      ++ (mapAttrsToList
        (
          keySequence: subCommand:
          let
            desc =
              if subCommand == null then
                "Trouble: toggle diagnostics"
              else
                "Trouble: toggle "
                + (replaceStrings
                  [
                    "_"
                    "loclist"
                  ]
                  [
                    " "
                    "location list"
                  ]
                  subCommand
                );
          in
          {
            action = concatStrings (
              [ "<cmd>Trouble" ]
              ++ optionals (subCommand != null) [
                " "
                subCommand
              ]
              ++ [ "<CR>" ]
            );
            key = "<Leader>" + keySequence;
            options = {
              inherit desc;
              silent = true;
            };
          }
        )
        {
          xx = null;
          xw = "workspace_diagnostics";
          xd = "document_diagnostics";
          xl = "loclist";
          xq = "quickfix";
        }
      );
  };
}
