{ helpers, ... }:
{
  config = {
    plugins.overseer = {
      enable = true;
      # TODO: lazy load on commands/keys
      lazyLoad.settings.event = "DeferredUIEnter";
    };
    keymaps = [
      {
        key = "<leader>or";
        action = "<cmd>OverseerRun<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: run task";
        };
      }
      {
        key = "<leader>ot";
        action = "<cmd>OverseerToggle<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: toggle tasks pane";
        };
      }
      {
        key = "<leader>ol";
        action = "<cmd>OverseerRestartLast<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: restart last task";
        };
      }
      {
        key = "<leader>oa";
        action = "<cmd>OverseerTaskAction<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: task action";
        };
      }
      {
        key = "<leader>oi";
        action = "<cmd>OverseerInfo<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: diagnostic info";
        };
      }
    ];
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
