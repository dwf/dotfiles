{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  config = {
    extraFiles."lua/completion.lua".source = ../lua/completion.lua;
    opts.completeopt = "menu,menuone,noselect,popup,fuzzy";
    keymaps = [
      {
        key = "<C-Space>";
        action = helpers.mkRaw ''
          function()
            vim.lsp.completion.get()
          end
        '';
        mode = "i";
        options.desc = "Trigger completion";
      }
    ];
    # <Tab> itself is bound centrally in ../keymaps/default.nix, which falls
    # through to the native completion popup (pumvisible()/complete_info())
    # as its last priority behind luasnip/LSP inline completion/blink-edit.
  };
}
