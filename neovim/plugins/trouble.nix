{ lib, ... }:
{
  config = {
    plugins.trouble = {
      enable = true;
      lazyLoad.settings.event = "DeferredUIEnter";
      settings = {
        auto_open = false;
        auto_close = true;
      };
    };

    keymaps =
      with lib;
      mapAttrsToList
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
        };
  };
}
