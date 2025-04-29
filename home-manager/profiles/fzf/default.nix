{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs = {
    fzf = {
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
    bash = lib.mkIf config.programs.fzf.enableBashIntegration {
      initExtra = lib.mkAfter (builtins.readFile ./ripgrep.sh);
    };
    zsh = lib.mkIf config.programs.fzf.enableZshIntegration {
      initExtra = lib.mkAfter (builtins.readFile ./ripgrep.sh);
    };
  };

  home = {
    shellAliases = {
      frg = "rfv";
    };
    packages = [
      (pkgs.writeShellScriptBin "git-fzs" (
        builtins.readFile (
          pkgs.replaceVars ./fzf_git_status.sh {
            inherit (pkgs)
              bat
              boxes
              eza
              fzf
              git
              ;
          }
        )
      ))
    ];
  };
}
