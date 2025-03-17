{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./zsh-nix-shell.nix
  ];
  options.programs.zsh.fzf-tab =
    let
      inherit (lib) types;
    in
    {
      dirPreviewCmd = lib.mkOption {
        default = "${pkgs.eza}/bin/eza";
        type = types.str;
      };
      dirPreviewCmdOpts = lib.mkOption {
        default = [
          "-w $(expr $COLUMNS / 2 - 4)"
          "-F"
          "--color=always"
          "--icons"
          "--group-directories-first"
        ];
        type = with types; nullOr (listOf str);
      };
      filePreviewCmd = lib.mkOption {
        default = "${pkgs.bat}/bin/bat";
        type = types.str;
      };
      filePreviewCmdOpts = lib.mkOption {
        default = [ "--color=always" ];
        type = with types; nullOr (listOf str);
      };
    };
  config.programs.zsh =
    let
      ftcfg = config.programs.zsh.fzf-tab;
      ifNotNull = l: lib.optionals (l != null) l;
      dirPreview =
        with ftcfg;
        lib.concatStringsSep " " ([ dirPreviewCmd ] ++ (ifNotNull dirPreviewCmdOpts) ++ [ "$realpath" ]);
      filePreview =
        with ftcfg;
        lib.concatStringsSep " " ([ filePreviewCmd ] ++ (ifNotNull filePreviewCmdOpts) ++ [ "$realpath" ]);
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
      initExtra =
        let
          shellFunctions = pkgs.writeShellScript "functions.sh" (builtins.readFile ./functions.sh);
        in
        # sh
        ''
          # Helpful fzf key bindings for git repositories, from the fzf author.
          source ${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh

          # Default history widget clobbers the plugin's binding; restore it.
          bindkey -r ^r
          bindkey ^r fzf_history_search

          source ${shellFunctions}
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
        # Auto-colorize `--help` output.
        {
          name = "zsh-help";
          src = pkgs.fetchFromGitHub {
            owner = "Freed-Wu";
            repo = "zsh-help";
            rev = "95cbc114078d8209730e38c72a6fa5859ca0773d";
            sha256 = "sha256-ij+ooXQxV3CmsCN/CrJMicTWvS+9GYHA/1Kuqh5zXIY=";
          };
        }
      ];

      # Also installs a plugin.
      syntaxHighlighting.enable = true;
    };

}
