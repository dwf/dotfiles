{ pkgs, ... }:
{
  programs.zsh =
    let
      dirPreview = "${pkgs.eza}/bin/eza -w $(expr $COLUMNS / 2 - 4) -F --color=always --icons --group-directories-first $realpath";
      filePreview = "${pkgs.bat}/bin/bat --color=always $realpath";
    in
    {
      enable = true;
      enableCompletion = true;
      initExtraBeforeCompInit = ''
        source ${pkgs.nix-zsh-completions}/share/zsh/plugins/nix/nix-zsh-completions.plugin.zsh
        fpath=(${pkgs.nix-zsh-completions}/share/zsh/site-functions $fpath)
        fpath=(${pkgs.nix}/share/zsh/site-functions $fpath)
        fpath=(${pkgs.zsh-completions}/share/zsh/site-functions $fpath)
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:*' fzf-preview '[ -d "$realpath" ] && ${dirPreview} || ${filePreview}'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview '${dirPreview}'
        zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview '${dirPreview}'

        zstyle ':fzf-tab:*' continuous-trigger '/'
        zstyle ':fzf-tab:*' fzf-flags --select-1 --bind=tab:accept
      '';
      initExtra = ''
        source ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh
      '';
      plugins = with pkgs; [
        {
          name = "fzf-tab";
          src = zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
        {
          name = "zsh-autosuggestions";
          src = zsh-autosuggestions;
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
        }
        # Hit Esc twice to prefix last command with sudo.
        {
          name = "sudo.plugin.zsh";
          src = oh-my-zsh;
          file = "share/oh-my-zsh/plugins/sudo/sudo.plugin.zsh";
        }
      ];
      syntaxHighlighting.enable = true;
    };

}
