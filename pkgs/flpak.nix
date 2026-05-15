{ lib, pkgs, ... }:
let
  inherit (pkgs) rustPlatform fetchFromGitHub;
in
rustPlatform.buildRustPackage rec {
  pname = "flpak";
  version = "0.5.2";

  src = fetchFromGitHub {
    owner = "lxndr";
    repo = "flpak";
    rev = "v${version}";
    hash = "sha256-G/BJ76TKt3VpIgFXTv6a0jVHyPyhd4eUuHWv1tFDchY=";
  };

  cargoHash = "sha256-ZXRX5FQYQInCMvNAPVk52qfgR7LaIOrq6O4yHA9KBYU=";

  meta = with lib; {
    description = "A utility to work with some types of archive: bsa, ba2, rpa, vpk, pak, zip";
    homepage = "https://github.com/lxndr/flpak";
    license = licenses.asl20;
    platforms = platforms.all;
    mainProgram = "flpak";
  };
}
