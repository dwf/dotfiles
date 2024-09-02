{ helpers, pkgs, ... }:
{
  config = {
    # autoCmd = [
    #   {
    #     event = [ "BufReadPre" ];
    #     callback =
    #       helpers.mkRaw # lua
    #         ''
    #           function()
    #             local bufnr = vim.api.nvim_get_current_buf()
    #             vim.schedule(function()
    #               if vim.api.nvim_buf_get_name(bufnr):match("^/home/dwf/src/foo/.*") then
    #                 vim.fn['sy#start']()
    #               end
    #             end)
    #           end
    #         '';

    #   }
    # ];
    extraPlugins = with pkgs.vimPlugins; [ vim-signify ];
    extraConfigLua = # lua
      ''
        vim.api.nvim_set_hl(0, "SignifySignAdd", { link = "GitSignsAdd" })
        vim.api.nvim_set_hl(0, "SignifySignChange", { link = "GitSignsChange" })
        vim.api.nvim_set_hl(0, "SignifySignChangeDelete", { link = "GitSignsChange" })
        vim.api.nvim_set_hl(0, "SignifySignDelete", { link = "GitSignsDelete" })
        vim.api.nvim_set_hl(0, "SignifySignDeleteFirstLine", { link = "GitSignsDelete" })
      '';
    globals = {
      signify_sign_add = "▎";
      signify_sign_change = "▎";
      signify_sign_delete = "";
      signify_sign_delete_first_line = "";
      signify_sign_change_delete = "";
      signify_skip.vcs.allow = [ "hg" ];
    };
    plugins.lualine.sections.lualine_b = [
      { name = "branch"; } # TODO
      {
        name = "diff";
        extraConfig.source =
          helpers.mkRaw # lua
            ''
              function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed
                  }
                elseif vim.fn.exists('sy#repo#get_stats') == 1 then
                  local stats = vim.fn['sy#repo#get_stats']()
                  return {
                    added = stats[1],
                    modified = stats[2],
                    removed = stats[3],
                  }
                end
              end
            '';
      }
      { name = "diagnostics"; }
    ];

  };
}
