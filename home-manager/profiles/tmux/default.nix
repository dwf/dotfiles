{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    customPaneNavigationAndResize = true; # sets Prefix-hjkl/HJKL mappings.
    baseIndex = 1;
    extraConfig = builtins.readFile ./tmux.conf;
    historyLimit = 100000;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [ tmux-fzf ];
    # terminal = "screen-256color";
  };
}
