{ lib, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      eza = super.eza.overrideAttrs (drv: rec {
        version = "0.20.10";
        src = self.fetchFromGitHub {
          owner = "eza-community";
          repo = "eza";
          rev = "v${version}";
          hash = "sha256-zAyklIIm6jAhFmaBu3BEysLfGEwB34rpYztZaJEQtYg=";
        };
        cargoHash = "sha256-fXrw753Hn4fbeX6+GRoH9MKrH0udjxnBK7AVCHnqIcs=";
        cargoDeps = drv.cargoDeps.overrideAttrs (
          lib.const {
            name = "${drv.pname}-${version}-vendor.tar.gz";
            inherit src;
            outputHash = cargoHash;
          }
        );
      });
    })
  ];

}
