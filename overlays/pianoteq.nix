# Work around the broken binary fetching logic in the pianoteq nixpkgs derivation
# (which seems quite brittle and I'm not sure how to fix).
{ lib, pkgs, ... }:
let
  # Host the binary package(s) on a webserver on my tailnet.
  distRoot = "http://bumblebee/dist";
in
{
  nixpkgs.overlays = [
    (
      _: super:
      let
        version = "8.0.8";
        overriddenPianoteq =
          name:
          {
            filename,
            sha256,
            base ? null,
          }:
          let
            basePkg = if base == null then name else base;
          in
          super.pianoteq."${basePkg}".overrideAttrs (_: {
            inherit version;
            pname = "pianoteq-${name}";
            src = pkgs.fetchurl {
              inherit sha256;
              url = "${distRoot}/${filename}";
            };
          });
      in
      {
        pianoteq = lib.mapAttrs overriddenPianoteq {
          standard-trial = {
            filename = "pianoteq_linux_trial_v808.7z";
            sha256 = "sha256-LSrnrjkEhsX9TirUUFs9tNqH2A3cTt3I7YTfcTT6EP8=";
          };
          stage-trial = {
            filename = "pianoteq_stage_linux_trial_v808.7z";
            sha256 = "sha256-dp0bTzzh4aQ2KQ3z9zk+3meKQY4YRYQ86rccHd3+hAQ=";
          };
          stage-8 = {
            filename = "pianoteq_stage_linux_v808.7z";
            sha256 = "sha256-9TEIKyzKu6fsLGLt+LOHiRHqnwZS0G+QoKw2KUzjwQM=";
            base = "stage-7";
          };
        };
      }
    )
  ];
}
