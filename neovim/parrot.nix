{ pkgs, ... }:
{
  config = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin rec {
        pname = "parrot-nvim";
        version = "v0.6.0";
        src = pkgs.fetchFromGitHub {
          owner = "frankroeder";
          repo = "parrot.nvim";
          rev = version;
          sha256 = "sha256-jZFnC1GA4xBRqdcSTzWGu0C0McFKro3To/gxgZayTZU=";
        };
        dependencies = with pkgs.vimPlugins; [
          plenary-nvim
          fzf-lua
        ];
      })
    ];
    extraConfigLua = # lua
      ''
        require('parrot').setup {
          providers = { ollama = {} }
        }
      '';
  };
}
