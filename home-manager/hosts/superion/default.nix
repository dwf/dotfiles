{
  imports = [
    ../.
    ../../profiles/x11/laptop.nix
    ./audio.nix
  ];

  programs.texlive = {
    enable = true;
    extraPackages = tpkgs: { inherit (tpkgs) scheme-small; };
  };

  services.redshift = {
    enable = true;
    provider = "manual";
    latitude = "51.5007";
    longitude = "0.1246";
    tray = true;
  };

  services.picom.vSync = true;
}
