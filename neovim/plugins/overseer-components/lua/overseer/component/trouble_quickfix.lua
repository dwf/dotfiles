return {
  desc = "Manage trouble.nvim quickfix state when task completes",
  params = {
    open_statuses = {
      desc = "List of statuses that will trigger Trouble to open",
      type = "list",
      subtype = {
        type = "enum",
        choices = { "SUCCESS", "FAILURE", "CANCELED" },
      },
      default = { "FAILURE" }, -- By default, open on failure
    },
    close_statuses = {
      desc = "List of statuses that will trigger Trouble to close",
      type = "list",
      subtype = {
        type = "enum",
        choices = { "SUCCESS", "FAILURE", "CANCELED" },
      },
      default = { "SUCCESS" }, -- By default, close on success
    },
  },
  constructor = function(params)
    return {
      ---@diagnostic disable-next-line: unused-local
      on_complete = function(self, task, status, result)
        -- Schedule ensures the quickfix list is fully populated first
        vim.schedule(function()
          local ok, trouble = pcall(require, "trouble")
          if not ok then
            vim.notify("trouble.nvim is not installed", vim.log.levels.WARN)
            return
          end

          -- Check which action to take based on the parameters
          if vim.tbl_contains(params.open_statuses, status) then
            trouble.open("quickfix")
          elseif vim.tbl_contains(params.close_statuses, status) then
            trouble.close("quickfix")
          end
        end)
      end,
    }
  end,
}
