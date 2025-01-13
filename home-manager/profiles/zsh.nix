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
      initExtraBeforeCompInit = # sh
        ''
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
      initExtra = # sh
        ''
          # Helpful fzf key bindings for git repositories, from the fzf author.
          source ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh

          # Default history widget clobbers the plugin's binding; restore it.
          bindkey -r ^r
          bindkey ^r fzf_history_search

          # run zsh inside `nix develop`.
          nix() {
            if [[ $1 == "dev" ]]; then
              shift
              command nix develop -c $SHELL "$@"
            else
              command nix "$@"
            fi
          }
        '';

      plugins = with pkgs; [
        # Replace the built-in tab completion into fzf-based completion.
        {
          name = "fzf-tab";
          src = zsh-fzf-tab;
          file = "share/fzf-tab/fzf-tab.plugin.zsh";
        }
        # Fish-style autosuggestions as-you-type. There is a home-manager
        # option for this, but according to the fzf-tab README, "fzf-tab needs
        # to be loaded after compinit, but before plugins which will wrap
        # widgets, such as zsh-autosuggestions or fast-syntax-highlighting".
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
        # More configurable Ctrl+R with better defaults.
        {
          name = "zsh-fzf-history-search";
          src = zsh-fzf-history-search;
          file = "share/zsh-fzf-history-search/zsh-fzf-history-search.plugin.zsh";
        }
      ];

      # Also installs a plugin.
      syntaxHighlighting.enable = true;
    };

}
