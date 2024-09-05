{ helpers, lib, ... }:
{
  config.autoCmd =
    let
      nestKeymapsCallbackFn =
        mappings:
        let
          keymapCmd =
            {
              key,
              desc,
              cmd,
            }:
            # lua
            ''
              vim.keymap.set( "n", "${key}", "<cmd>${cmd}<cr><cmd>nohl<cr>", { buffer = true, desc = "${desc}"})
            '';
        in
        helpers.mkRaw # lua
          ''
            function()
              vim.schedule(function()
                ${lib.concatStringsSep "\n" (map keymapCmd mappings)}
              end)
            end
          '';
    in
    [
      {
        event = [ "FileType" ];
        pattern = [ "nix" ];
        callback = nestKeymapsCallbackFn [
          # There is surely a more robust way to do this with treesitter.
          # N.B. ''double single-quote strings'' with no trailing \n, to
          # avoid quadruple backslash (one layer for nix, one for lua)
          {
            key = "<leader>nnt";
            cmd = ''s/^\\([^\\.]\\+\\)\\.\\([^ =]\\+\\)\\ \\?=\\ \\?\\([^;]\\+\\);$/\\1 = { \\2 = \\3; };/e'';
            desc = "Nest top level of a one-line dotted attrset assign";
          }
          {
            key = "<leader>nnb";
            cmd = ''s/\\(.\\+\\)\\.\\([^ =]\\+\\)\\ \\?=\\ \\?\\([^;]\\+\\);$/\\1 = { \\2 = \\3; };/e'';
            desc = "Nest bottom level of a one-line dotted attrset assign";
          }
        ];
      }
    ];
}
