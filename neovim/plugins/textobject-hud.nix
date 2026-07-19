{ pkgs, lib, ... }:
{
  config =
    let
      rev = "51a49bd5c570cb630ea0749638863e6bae9407e0";
      hash = "sha256-veNUS6kWPoGpAtHn/t4qaHURg2LAEfMIgfPacd71PPI=";
      pname = "textobject-hud.nvim";
    in
    {
      extraPlugins = [
        {
          optional = true;
          plugin = pkgs.vimUtils.buildVimPlugin {
            inherit pname;
            version = builtins.substring 0 8 rev;
            src = pkgs.fetchFromGitHub {
              owner = "so1ve";
              repo = pname;
              inherit rev hash;
            };
          };
        }
      ];
      plugins.lz-n.plugins = [
        {
          __unkeyed-1 = pname;
          event = [ "DeferredUIEnter" ];
          after = lib.nixvim.mkRaw ''
            function()
              require("textobject-hud").setup {}
            end
          '';
          keys = [
            {
              __unkeyed-1 = "<leader>h";
              __unkeyed-2 = lib.nixvim.mkRaw "function() require('textobject-hud').open {} end";
              desc = "Trigger textobject-hud.nvim";
            }
          ];
        }
      ];
    };
}
