{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    fileWidgetCommand = "fd --type f --color=always";
    fileWidgetOptions = [
      "--ansi"
      "--preview '${pkgs.bat}/bin/bat --color=always {}'"
    ];
    changeDirWidgetCommand = "fd --type d --color=always";
    changeDirWidgetOptions = [
      "--ansi"
      "--preview '${pkgs.eza}/bin/eza --color=always --group-directories-first --icons -F {} -1'"
    ];
  };
}
