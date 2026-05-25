{ pkgs, ... }:
{
  config = {
    extraPlugins = [
      {
        plugin =
          let
            rev = "f1272ab7ae69601d4a548acee29625efaff0eea5";
            hash = "sha256-dEQMw+s2ox7rKuYnG+RdWGNeW1LUBi2S7jFXhLFa5xI=";
          in
          pkgs.vimUtils.buildVimPlugin {
            pname = "awk-ward.nvim";
            version = builtins.substring 0 8 rev;
            src = pkgs.fetchFromGitLab {
              inherit rev hash;
              owner = "HiPhish";
              repo = "awk-ward.nvim";
            };
          };
        optional = true;
      }
    ];
    plugins.lz-n.plugins = [
      {
        __unkeyed-1 = "awk-ward.nvim";
        cmd = [ "AwkWard" ];
      }
    ];
  };
}
