{ pkgs, ... }:
{
  config = {
    extraPackages = with pkgs; [
      nixfmt-rfc-style
      stylua
    ];
    plugins.conform-nvim = {
      enable = true;
      settings = {
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
        format_on_save = {
          quiet = false;
        };
      };
    };
  };
}
