{ lib, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      vivid = super.vivid.overrideAttrs (drv: rec {
        version = "0.10.1";
        src = self.fetchFromGitHub {
          owner = "sharkdp";
          repo = "vivid";
          rev = "v${version}";
          hash = "sha256-mxBBfezaMM2dfiXK/s+Htr+i5GJP1xVSXzkmYxEuwNs=";
        };
        cargoHash = "sha256-B1PYLUtBcx35NkU/NR+CmM8bF0hfJWmu11vsovFwR+c=";
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
