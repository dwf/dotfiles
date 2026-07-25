{ lib, ... }:
{
  config = {
    plugins.trouble = {
      enable = true;
      lazyLoad.settings = {
        keys =
          with lib;
          mapAttrsToList
            (keySequence: cfg: {
              __unkeyed-1 = "<Leader>" + keySequence;
              __unkeyed-2 =
                "<cmd>Trouble "
                + cfg.mode
                + " toggle"
                + (optionalString (cfg ? args) (" " + concatStringsSep " " cfg.args))
                + "<CR>";
              inherit (cfg) desc;
              silent = true;
            })
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
      settings = {
        auto_open = false;
        auto_close = true;
      };
    };
  };
}
