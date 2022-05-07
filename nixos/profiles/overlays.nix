{ pkgs, ... }:
{
  # Use latest Caddy for Tailscale certificate support.
  nixpkgs.overlays = [
    (_: super: {
      caddyLatest =
        let
          version = "2.5.1";
          src = pkgs.fetchFromGitHub {
            owner = "caddyserver";
            repo = "caddy";
            rev = "v${version}";
            sha256 = "";
          };
          vendorSha256 = "";
        in
        (super.caddy.override {
          buildGoModule = args: super.buildGoModule (args // {
            inherit src version vendorSha256;
          });
        });
    })
  ];
}
