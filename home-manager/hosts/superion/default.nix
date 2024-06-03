{ ... }:
{
  imports = [
    ../.
    ../../profiles/desktop/laptop.nix
    ../../profiles/wayland.nix
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.picom.vSync = true;
}
