{ pkgs, ... }:
{
  config.plugins.trim = {
    enable = true;
    lazyLoad.settings.event = "DeferredUIEnter";
    package = pkgs.vimUtils.buildVimPlugin {
      pname = "trim.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "cappyzawa";
        repo = "trim.nvim";
        rev = "84a1016c7484943e9fbb961f807c3745342b2462";
        sha256 = "sha256-RzLttgP3eNQK8iQ86/7SwvB/GF8LCNlBhvZevOXMhSM=";
      };
      version = "2024-11-21";
    };
    settings = {
      ft_blocklist = [
        "diff"
        "hgcommit"
        "gitcommit"
      ];
      highlight = true;
    };
  };
}
