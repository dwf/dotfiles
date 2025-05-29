{ pkgs, ... }:
{
  imports = [
    ../.
    ../../profiles/wayland.nix
  ];

  home.packages = with pkgs; [ calibre ];
}
