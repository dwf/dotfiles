{ lib, pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    customPaneNavigationAndResize = true; # sets Prefix-hjkl/HJKL mappings.
    baseIndex = 1;
    extraConfig = lib.concatStringsSep "\n" [
      ''
        set -g status-position top
      ''
      (builtins.readFile ./tmux.conf)
      (builtins.readFile "${pkgs.vimPlugins.tokyonight-nvim}/extras/tmux/tokyonight_moon.tmux")
    ];

    historyLimit = 100000;
    keyMode = "vi";
    terminal = "screen-256color";

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
    ];
  };
}
