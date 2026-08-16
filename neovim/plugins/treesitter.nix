{
  config.plugins.treesitter = {
    enable = true;
    # Deliberately not lazy-loaded: syntax highlighting is needed for almost
    # every real editing session, so there's essentially nothing to defer,
    # unlike genuinely occasional-use plugins (sidekick, twilight, codediff,
    # snacks pickers, ...). Lazy-loading it anyway (on DeferredUIEnter) only
    # bought a race between a manual `after` hook and this plugin's own
    # generated highlighting-autocmd setup, on top of a structural race
    # where a file passed on the command line gets its FileType event
    # *before* DeferredUIEnter can possibly fire (DeferredUIEnter waits on
    # UIEnter) - meaning the very first buffer of any session could silently
    # never get highlighted. Not worth the complexity for the (near-zero)
    # startup-time savings.
    highlight = {
      enable = true;
      disable = [
        "tmux" # the treesitter grammar has a bug with 'set -g status' [no value]
      ];
    };
  };

  # Inject awk syntax highlighting into strings following an
  # "awk" command. Also works in justfile recipes.
  config.extraFiles."after/queries/bash/injections.scm".text = ''
    ;; extends

    ; awk 'program'
    ((command
      name: (command_name) @_command
      argument: (raw_string) @injection.content)
      (#eq? @_command "awk")
      (#offset! @injection.content 0 1 0 -1)
      (#set! injection.language "awk"))
  '';
}
