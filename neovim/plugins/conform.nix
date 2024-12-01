{ pkgs, ... }:
{
  config = {
    extraPackages = with pkgs; [
      nixfmt-rfc-style
      stylua
    ];
    plugins.conform-nvim = {
      enable = true;
      formatters.stylua = {
        prepend_args = [
          "--indent-type"
          "spaces"
          "--indent-width"
          "2"
        ];
      };
      formattersByFt = {
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
      };
      settings.format_on_save = { };
    };
  };
}
