# Work around the broken binary fetching logic in the pianoteq nixpkgs derivation
# (which seems quite brittle and I'm not sure how to fix).
{ config, nixpkgs, pkgs, ... }:
let
  # Host the binary package(s) on a webserver on my tailnet.
  distRoot = "http://bumblebee/dist";
in
{
  nixpkgs.overlays = [
    (self: super: {
      pianoteq.standard-trial = super.pianoteq.standard-trial.overrideAttrs (_: {
        version = "8.0.8";
        src = pkgs.fetchurl {
          url = "${distRoot}/pianoteq_linux_trial_v808.7z";
          sha256 = "sha256-LSrnrjkEhsX9TirUUFs9tNqH2A3cTt3I7YTfcTT6EP8=";
        };
      });
    })
  ];
}
