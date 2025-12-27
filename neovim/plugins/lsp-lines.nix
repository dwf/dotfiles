{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    plugins.lsp-lines = {
      enable = true;
      lazyLoad.settings.event = "DeferredUIEnter";
    };
    keymaps = [
      {
        action =
          helpers.mkRaw # lua
            ''
              function()
                vim.schedule(function()
                  local current_config = vim.diagnostic.config()
                  if current_config.virtual_lines then
                    vim.diagnostic.config({ virtual_lines = false, virtual_text = true })
                  elseif current_config.virtual_text then
                    vim.diagnostic.config({ virtual_lines = false, virtual_text = false })
                  elseif not (current_config.virtual_lines or current_config.virtual_text) then
                    vim.diagnostic.config({ virtual_lines = true, virtual_text = false })
                  end
                end)
              end
            '';
        key = "<leader>xv";
        mode = [
          "n"
          "v"
        ];
        options = {
          silent = true;
          desc = "Toggle diagnostics display (virtual lines, virtual text, off)";
        };
      }
    ];
  };
}
