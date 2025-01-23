{
  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ];
  };
  home.shellAliases = {
    # Also alias the original zoxide commands.
    z = "cd";
    zi = "cdi";
  };
}
