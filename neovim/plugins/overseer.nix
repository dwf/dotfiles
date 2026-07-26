{ lib, pkgs, ... }:
let
  helpers = lib.nixvim;
in
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
        {
          __unkeyed-1 = "overseer";
          status = [
            "RUNNING"
            "CANCELED"
          ];
        }
      ];
    };
    plugins.overseer = {
      enable = true;
      lazyLoad.settings = {
        # overseer.nvim's own registered commands (lua/overseer/init.lua's
        # `commands` table) - covers direct :OverseerX use in addition to
        # the keys below (some of which already dispatch through these same
        # commands, but typing the command directly should also work).
        cmd = [
          "OverseerOpen"
          "OverseerClose"
          "OverseerToggle"
          "OverseerRun"
          "OverseerShell"
          "OverseerTaskAction"
        ];
        # overseer-components (below) defines custom overseer.component.*
        # modules that overseer itself require()s by name when a task
        # references them, so it needs to already be on the runtimepath by
        # the time overseer finishes loading.
        before = helpers.mkRaw ''
          function()
            require('lz.n').trigger_load('overseer-components')
          end
        '';
        keys = [
          {
            __unkeyed-1 = "<leader>or";
            __unkeyed-2 = "<cmd>OverseerRun<cr>";
            mode = [ "n" ];
            desc = "overseer.nvim: run task";
          }
          {
            __unkeyed-1 = "<leader>ot";
            __unkeyed-2 = helpers.mkRaw ''
              function()
                require('overseer').toggle({ enter = false })
              end
            '';
            mode = [ "n" ];
            desc = "overseer.nvim: toggle tasks pane";
          }
          {
            __unkeyed-1 = "<leader>oT";
            __unkeyed-2 = helpers.mkRaw ''
              function()
                require('overseer').toggle({ enter = true })
              end
            '';
            mode = [ "n" ];
            desc = "overseer.nvim: toggle tasks pane with focus";
          }
          {
            __unkeyed-1 = "<leader>oa";
            __unkeyed-2 = "<cmd>OverseerTaskAction<cr>";
            mode = [ "n" ];
            desc = "overseer.nvim: task action";
          }
          {
            __unkeyed-1 = "<leader>os";
            __unkeyed-2 = "<cmd>OverseerShell<cr>";
            mode = [ "n" ];
            desc = "overseer.nvim: shell";
          }
          # TODO: verify this still works after breaking changes
          {
            __unkeyed-1 = "<leader>ol";
            __unkeyed-2 = "<cmd>OverseerRestartLast<cr>";
            mode = [ "n" ];
            desc = "overseer.nvim: restart last task";
          }
          {
            __unkeyed-1 = "<leader>ow";
            __unkeyed-2 = helpers.mkRaw ''
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
            desc = "overseer.nvim: watch current buffer with last task";
          }
        ];
      };
    };
    extraPlugins = [
      {
        optional = true;
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "overseer-components";
          version = "2026-07-17";
          src = ./overseer-components;
        };
      }
    ];
    # No trigger of its own (only ever consumed by overseer, forced via its
    # before hook above) - `lazy = true` just keeps it out of startup load.
    plugins.lz-n.plugins = [
      {
        __unkeyed-1 = "overseer-components";
        lazy = true;
      }
    ];
    userCommands = {
      # https://github.com/stevearc/overseer.nvim/blob/dc67e8500b81dcfe18192e900f952be73966c35f/doc/recipes.md
      # TODO: verify this still works after breaking changes
      OverseerRestartLast = {
        command = helpers.mkRaw ''
          function()
            -- Custom command, not one of overseer's own (see cmd list
            -- above), so it isn't covered by a lz.n cmd trigger - force
            -- the load here since this can be invoked directly.
            require('lz.n').trigger_load('overseer.nvim')
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
