{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    extraConfig = builtins.readFile ./tmux.conf;
    historyLimit = 100000;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [ tmux-fzf ];
    # terminal = "screen-256color";
  };
}
