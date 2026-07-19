{ lib, ... }:
let
  helpers = lib.nixvim;
in
{
  files."ftplugin/nix.lua".keymaps = [
    {
      key = "<leader>nh";
      action = helpers.mkRaw ''
        function()
          require('nix-fetch-hash').fill_hash(0)
        end
      '';
      mode = [ "n" ];
      options = {
        buffer = true;
        desc = "Fill in sha256/hash for fetchFromGitHub call under cursor";
      };
    }
  ];
}
