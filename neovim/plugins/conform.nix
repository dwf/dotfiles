{ pkgs, lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    extraPackages = with pkgs; [
      nixfmt-rfc-style
      stylua
    ];

    # Most of the Lua code here lifted from https://github.com/stevearc/conform.nvim/blob/master/doc/recipes.md
    plugins.conform-nvim = {
      enable = true;
      luaConfig = {
        pre = ''
          -- Global table tracking filetypes where formatting has been adaptively changed
          -- to async / after save.
          slow_format_filetypes = {}
        '';
        post = ''
          vim.o.formatexpr = "v:lua.require'conform'.formatexpr()";
        '';
      };
      lazyLoad.settings = {
        event = "BufWritePre";
        cmd = [
          # Commands other than ConformInfo defined in the before hook (below)
          "ConformInfo"
          "Format"
          "FormatEnable"
          "FormatDisable"
        ];
        keys = [
          {
            __unkeyed-1 = "<leader>f";
            __unkeyed-2 = helpers.mkRaw ''
              function()
                require("conform").format({ async = true }, function(err)
                  if not err then
                    local mode = vim.api.nvim_get_mode().mode
                    if vim.startswith(string.lower(mode), "v") then
                      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
                    end
                  end
                end)
              end
            '';
            mode = [
              "n"
              "v"
            ];
            desc = "Format code";
          }
        ];
        before = helpers.mkRaw ''
          function()
            vim.api.nvim_create_user_command("Format", function(args)
              local range = nil
              if args.count ~= -1 then
                local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
                range = {
                  start = { args.line1, 0 },
                  ["end"] = { args.line2, end_line:len() },
                }
              end
              require("conform").format({ async = true, lsp_format = "fallback", range = range })
            end, { range = true })

            vim.api.nvim_create_user_command("FormatDisable", function(args)
              if args.bang then
                -- FormatDisable! will disable formatting just for this buffer
                vim.b.disable_autoformat = true
                vim.notify('autoformat-on-save disabled for current buffer', vim.log.levels.INFO, { title = 'conform' })
              else
                vim.g.disable_autoformat = true
                vim.notify('autoformat-on-save disabled globally', vim.log.levels.INFO, { title = 'conform' })
              end
            end, {
              desc = "Disable autoformat-on-save",
              bang = true,
            })

            vim.api.nvim_create_user_command("FormatEnable", function()
              vim.b.disable_autoformat = false
              vim.g.disable_autoformat = false
              vim.notify('autoformat-on-save re-enabled', vim.log.levels.INFO, { title = 'conform' })
            end, {
              desc = "Re-enable autoformat-on-save",
            })
          end
        '';
      };
      settings = {
        format_on_save = helpers.mkRaw ''
          function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
              return
            end
            if slow_format_filetypes[vim.bo[bufnr].filetype] then
              return
            end
            local function on_format(err)
              if err and err:match("timeout$") then
                slow_format_filetypes[vim.bo[bufnr].filetype] = true
              end
            end
            return { timeout_ms = 200, quiet = false }, on_format
          end
        '';
        format_after_save = helpers.mkRaw ''
          function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
              return
            end
            if not slow_format_filetypes[vim.bo[bufnr].filetype] then
              return
            end
            return { quiet = false }
          end
        '';
        formatters.stylua = {
          prepend_args = [
            "--indent-type"
            "spaces"
            "--indent-width"
            "2"
          ];
        };
        formatters_by_ft = {
          lua = [ "stylua" ];
          nix = [ "nixfmt" ];
        };
      };
    };
  };
}
