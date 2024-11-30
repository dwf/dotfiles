{ pkgs, lib, ... }:
{
  programs.zsh = {
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
      zstyle ':fzf-tab:complete:cd:*' fzf-preview '${pkgs.eza}/bin/eza -w $(expr $COLUMNS / 2 - 4) -F --color=always --icons --group-directories-first $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview '${pkgs.eza}/bin/eza --color=always --icons --group-directories-first $realpath'
      # zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
      zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept

    '';
    initExtra = lib.concatMapStrings (s: "source ${s}\n") (
      with pkgs;
      [
        "${oh-my-zsh}/share/oh-my-zsh/lib/git.zsh"
        "${oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh"
        "${oh-my-zsh}/share/oh-my-zsh/plugins/sudo/sudo.plugin.zsh"
        "${oh-my-zsh}/share/oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh"
      ]
    );
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];
    syntaxHighlighting.enable = true;
  };
}
