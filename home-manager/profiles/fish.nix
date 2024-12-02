{ pkgs, ... }:
{
  programs = {
    fish = {
      enable = true;
      interactiveShellInit = builtins.readFile "${pkgs.vimPlugins.tokyonight-nvim}/extras/fish/tokyonight_night.fish";
      plugins = with pkgs.fishPlugins; [
        {
          name = "fzf.fish";
          inherit (fzf-fish) src;
        }
        {
          name = "fifc";
          src = pkgs.stdenvNoCC.mkDerivation {
            pname = "fifc";
            version = "2024-12-02";
            src = pkgs.fetchFromGitHub {
              owner = "gazorby";
              repo = "fifc";
              rev = "e953fcd521f34651d4eabedcc08cfdef7945b31d";
              sha256 = "sha256-VmeVVwX5/rPZr98vaitvw6bqcZgaBNc+mEYkDRjFBXA=";
            };
            patches = [
              (pkgs.fetchpatch {
                url = "https://github.com/gazorby/fifc/pull/52/commits/d7a44c151e72185208781ad69420bef824093cce.patch";
                sha256 = "sha256-gpH29b2BgURr+wHSZErLbhaOBpCrwLxkQZBhw4m4/Pw=";
              })
            ];
            dontConfigure = true;
            dontBuild = true;
            installPhase = ''
              cp -R $src $out
            '';
          };
        }
      ];
    };
    fzf.enableFishIntegration = false;
  };

  xdg.configFile."fish/completions/nix.fish".source = "${pkgs.nix}/share/fish/vendor_completions.d/nix.fish";
}
