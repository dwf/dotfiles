{ helpers, ... }:
{
  config = {
    plugins.overseer = {
      enable = true;
      lazyLoad.settings.event = "DeferredUIEnter";
    };
    userCommands = {
      # https://github.com/stevearc/overseer.nvim/blob/dc67e8500b81dcfe18192e900f952be73966c35f/doc/recipes.md
      OverseerRestartLast = {
        command = helpers.mkRaw ''
          function()
            local overseer = require("overseer")
            local tasks = overseer.list_tasks({ recent_first = true })
            if vim.tbl_isempty(tasks) then
              vim.notify("No tasks found", vim.log.levels.WARN)
            else
              overseer.run_action(tasks[1], "restart")
            end
          end
        '';
      };
    };
  };
}
