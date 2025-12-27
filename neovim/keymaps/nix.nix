{
  files."ftplugin/nix.lua".keymaps = [
    # There is surely a more robust way to do this with treesitter.
    # N.B. ''double single-quote strings'' with no trailing \n, to
    # avoid quadruple backslash (one layer for nix, one for lua)
    {
      key = "<leader>nnt";
      action = ''s/^\\([^\\.]\\+\\)\\.\\([^ =]\\+\\)\\ \\?=\\ \\?\\([^;]\\+\\);$/\\1 = { \\2 = \\3; };/e'';
      mode = [ "n" ];
      options = {
        buffer = true;
        desc = "Nest top level of a one-line dotted attrset assign";
      };
    }
    {
      key = "<leader>nnb";
      action = ''s/\\(.\\+\\)\\.\\([^ =]\\+\\)\\ \\?=\\ \\?\\([^;]\\+\\);$/\\1 = { \\2 = \\3; };/e'';
      mode = [ "n" ];
      options = {
        buffer = true;
        desc = "Nest bottom level of a one-line dotted attrset assign";
      };
    }
    # {
    #   key = "<leader>ni";
    #   action =
    #     helpers.mkRaw # lua
    #       ''
    #         function()
    #           require('treesitter-helpers.nix').maybe_add_module_import(0, vim.fn.expand('<cword>'))
    #         end
    #       '';
    #   mode = [ "n" ];
    #   options = {
    #     buffer = true;
    #     desc = "Add module import for word under cursor (if not already imported)";
    #   };
    # }
    # {
    #   key = "<leader>na";
    #   action =
    #     helpers.mkRaw # lua
    #       ''
    #         function()
    #           local pos = require('treesitter-helpers.nix').get_first_module_argument_position(0)
    #           if pos ~= nil then
    #             local row = pos[1]
    #             local col = pos[2]
    #             vim.cmd("normal! m'")
    #             vim.api.nvim_win_set_cursor(0, { row + 1, col })
    #           end
    #         end
    #       '';
    #   mode = [ "n" ];
    #   options = {
    #     buffer = true;
    #     desc = "Jump to module arg list";
    #   };
    # }
  ];
}
