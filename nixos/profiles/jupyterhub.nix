{ config, pkgs, ... }:
let
  r-icons = pkgs.stdenvNoCC.mkDerivation {
    pname = "r-icons";
    version = "2016";
    src = pkgs.fetchurl {
      url = "https://www.r-project.org/logo/Rlogo.png";
      sha256 = "sha256-eLT8eVLxi83UgHfdUrt+taoHFBgo7HQ7lShEXEd3FYI=";
    };
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    buildInputs = [ pkgs.imagemagick ];
    installPhase = ''
      mkdir $out
      convert -background none -gravity center $src -resize 64x64 -extent 64x64 $out/64x64.png
      convert $out/64x64.png -resize 32x32 $out/32x32.png
    '';
  };
  python39Kernel =
    let env = pkgs.python39.withPackages(p: with p; [
      ipykernel
      numpy
      scipy
      matplotlib
      seaborn
    ]); in
    {
      displayName = "Python 3.9";
      argv =
        [
          "${env.interpreter}"
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
      language = "python";
      logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
      logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
    };
  rKernel =
    let env = pkgs.rWrapper.override {
      packages = with pkgs.rPackages; [
        IRkernel
        ggplot2
      ];
    };
    in {
      displayName = "R";
      argv = [
        "${env}/bin/R"
        "--slave"
        "-e"
        "IRkernel::main()"
        "--args"
        "{connection_file}"
      ];
      language = "R";
      logo32 = "${r-icons}/32x32.png";
      logo64 = "${r-icons}/64x64.png";
    };
  nixKernel =
    let
      env = pkgs.python3.withPackages(p: with p; [
        nix-kernel
      ]);
      iconBase = "${pkgs.nixos-icons}/share/icons/hicolor";
    in {
      displayName = "Nix";
      argv = [
        "${env.interpreter}"
        "-m"
        "nix-kernel"
        "-f"
        "{connection_file}"
      ];
      language = "Nix";
      logo32 = "${iconBase}/32x32/apps/nix-snowflake.png";
      logo64 = "${iconBase}/64x64/apps/nix-snowflake.png";
    };
  containerHostAddr = "10.233.4.1";
  containerGuestAddr = "10.233.4.2";
  jupyterHubPort = 8000;
  jupyterHubAddr = "${containerGuestAddr}:${toString jupyterHubPort}";
in
{
  containers.jupyterhub = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = containerHostAddr;
    localAddress = containerGuestAddr;
    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 8000 ];
      services.jupyterhub = {
        enable = true;
        host = containerGuestAddr;
        port = jupyterHubPort;
        kernels = {
          python39 = python39Kernel;
          r = rKernel;
          nix = nixKernel;
        };
        extraConfig = ''
          c.JupyterHub.bind_url = 'http://${jupyterHubAddr}/notebooks/'
        '';
      };
    };
  };
  services.tailscaleHttpsReverseProxy.routes.notebooks = {
    to = jupyterHubAddr;
    stripPrefix = false;
  };
}
