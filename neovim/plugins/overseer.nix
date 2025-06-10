{ helpers, lib, ... }:
{
  config = {
    plugins.lualine = {
      # Don't race overseer to start.
      lazyLoad.settings.before = helpers.mkRaw ''
        function()
          require('lz.n').trigger_load('overseer.nvim')
        end
      '';
      settings.sections.lualine_x = lib.mkBefore [
        "overseer"
      ];
    };
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
        key = "<leader>oa";
        action = "<cmd>OverseerQuickAction<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: quick action";
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
      {
        key = "<leader>of";
        action = "<cmd>OverseerQuickAction open float<cr>";
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: open last task terminal in float";
        };
      }
      {
        key = "<leader>ow";
        action = helpers.mkRaw ''
          function()
            local tasks = require('overseer').list_tasks({ recent_first = true })
            if #tasks > 0 then
              local path = vim.fn.expand("%:p")
              local existing_component = tasks[1]:get_component("restart_on_save")
              local notify_success = function()
                vim.notify(("Re-running task\n\n    %s\n\non each save of\n\n    %s"):format(tasks[1].name, path), vim.log.levels.INFO)
              end
              if existing_component ~= nil then
                for _, p in ipairs(existing_component.params.paths) do
                  if p == path then
                    vim.notify(("The task\n\n    %s\n\nis already watching\n\n    %s"):format(tasks[1].name, path), vim.log.levels.ERROR)
                    return
                  end
                end
                table.insert(existing_component.params.paths, path)
                notify_success()
              else
                local new_component = {
                  "restart_on_save",
                  paths = {path},
                  name = name
                }
                tasks[1]:add_component(new_component)
                notify_success()
              end
            end
          end
        '';
        mode = [ "n" ];
        options = {
          desc = "overseer.nvim: watch current buffer with last task";
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
