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
          keySequence: cfg:
          {
            action =
              "<cmd>Trouble "
              + cfg.mode
              + " toggle"
              + (optionalString (cfg ? args) (" " + concatStringsSep " " cfg.args))
              + "<CR>";
            key = "<Leader>" + keySequence;
            options = {
              inherit (cfg) desc;
              silent = true;
            };
          }
        )
        {
          xx = {
            mode = "diagnostics";
            desc = "Diagnostics (Trouble)";
          };
          xX = {
            mode = "diagnostics";
            args = [ "filter.buf=0" ];
            desc = "Buffer Diagnostics (Trouble)";
          };
          cs = {
            mode = "symbols";
            args = [ "focus=false" ];
            desc = "Symbols (Trouble)";
          };
          cl = {
            mode = "lsp";
            args = [
              "focus=false"
              "win.position=right"
            ];
            desc = "LSP Definitions / references / ... (Trouble)";
          };
          xl = {
            mode = "loclist";
            desc = "Location List (Trouble)";
          };
          xq = {
            mode = "qflist";
            desc = "Quickfix List (Trouble)";
          };
        };
  };
}
