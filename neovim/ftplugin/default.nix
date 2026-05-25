{ pkgs, ... }:
{
  files."ftplugin/awk.lua".opts = {
    expandtab = false;
    shiftwidth = 4;
    tabstop = 4;
  };
}
