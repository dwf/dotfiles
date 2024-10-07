{ helpers, ... }:
{
  files."ftplugin/python.lua".keymaps =
    let
      import-keymap =
        {
          key,
          which,
          desc,
        }:
        {
          inherit key;
          action =
            helpers.mkRaw # lua
              ''
                function()
                  require("treesitter-helpers.python").expand_import_snippet(${helpers.toLuaObject which})
                end
              '';
          mode = [ "n" ];
          options = {
            buffer = true;
            inherit desc;
          };
        };
    in
    [
      {
        key = "<Leader>il";
        action =
          helpers.mkRaw # lua
            ''
              require("treesitter-helpers.python").insert_after_last_import
            '';
        mode = [ "n" ];
        options = {
          buffer = true;
          desc = "Insert after last top-level import.";
        };
      }
    ]
    ++ (map import-keymap [
      {
        key = "<leader>im";
        which = "import";
        desc = "import <module>";
      }
      {
        key = "<leader>ia";
        which = "import_as";
        desc = "import <module> as <alias>";
      }
      {
        key = "<leader>if";
        which = "from_import";
        desc = "from <module> import <name>";
      }
      {
        key = "<leader>id";
        which = "from_import_as";
        desc = "from <module> import <name> as <alias>";
      }
    ]);
}
