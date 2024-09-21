{ pkgs, ... }:
{
  config = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "overseer-nvim";
        src = pkgs.fetchFromGitHub {
          owner = "stevearc";
          repo = "overseer.nvim";
          rev = "a2734d90c514eea27c4759c9f502adbcdfbce485";
          sha256 = "sha256-jRT2a8C/8V0tEwBlGRfQeVsUKzR2YinqinBkayvQRLo=";
        };
        version = "2024-09-22";
      })
    ];

    extraConfigLua = ''
      require('overseer').setup {}
    '';
  };

}
