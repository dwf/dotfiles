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
      mapAttrsToList
        (keySequence: subCommand: {
          action = concatStrings (
            [ "<cmd>Trouble" ]
            ++ optionals (subCommand != null) [
              " "
              subCommand
            ]
            ++ [ "<CR>" ]
          );
          key = "<Leader>" + keySequence;
          options.silent = true;
        })
        {
          xx = null;
          xw = "workspace_diagnostics";
          xd = "document_diagnostics";
          xl = "loclist";
          xq = "quickfix";
        };
  };
}
