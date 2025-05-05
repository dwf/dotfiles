{
  imports = [
    ./nix.nix
    ./python.nix
  ];

  config.keymaps = [
    {
      action = "\"hy:%s/<C-r>h//g<left><left>";
      key = "<leader>S";
      options = {
        desc = "Search and replace selection";
      };
      mode = "v";
    }
    {
      action = "\"syiw:%s/<C-r>s//g<left><left>";
      key = "<leader>S";
      options = {
        desc = "Search and replace word under cursor";
      };
      mode = "n";
    }
    {
      action = ":%s///g<left><left><left>";
      key = "<leader>s";
      options = {
        desc = "Search and replace";
      };
      mode = "n";
    }
  ];
}
