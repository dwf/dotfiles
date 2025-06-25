{
  imports = [
    ./nix.nix
  ];

  config.keymaps = [
    {
      action = "\"hy:%s/<C-r>h//g<left><left>";
      key = "<leader>R";
      options = {
        desc = "Search and replace selection";
      };
      mode = "v";
    }
    {
      action = "\"syiw:%s/<C-r>s//g<left><left>";
      key = "<leader>R";
      options = {
        desc = "Search and replace word under cursor";
      };
      mode = "n";
    }
    {
      action = ":%s///g<left><left><left>";
      key = "<leader>r";
      options = {
        desc = "Search and replace";
      };
      mode = "n";
    }
  ];
}
