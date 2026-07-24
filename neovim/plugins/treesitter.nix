{
  config.plugins.treesitter = {
    enable = true;
    lazyLoad.settings = {
      event = "DeferredUIEnter";
      after = ''
        function()
          vim.treesitter.start()
        end
      '';
    };
    highlight = {
      enable = true;
      disable = [
        "tmux" # the treesitter grammar has a bug with 'set -g status' [no value]
      ];
    };
  };
}
