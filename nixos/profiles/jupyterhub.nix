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

  mkPythonKernel = { displayName, pkgsFn, interpreter }:
  let
    env = interpreter.withPackages(pkgsFn);
  in {
    inherit displayName;
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
  mkRKernel = { displayName, packages, pkg ? pkgs.rWrapper }:
  let
    env = pkg.override {
      inherit packages;
    };
  in {
    inherit displayName;
    argv = [
      "${env}/bin/R"
      "--slave"
      "-e"
      "IRkernel::main()"
      "--args"
      "{connection_file}"
    ];
    language = "R ${pkgs.R.version}";
    logo32 = "${r-icons}/32x32.png";
    logo64 = "${r-icons}/64x64.png";
  };

  # TODO(dwf): figure out how to specify Nix version.
  mkNixKernel = { displayName }:
  let
    env = pkgs.python3.withPackages(p: with p; [
      nix-kernel
    ]);
    iconBase = "${pkgs.nixos-icons}/share/icons/hicolor";
  in {
    inherit displayName;
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
  mkPythonPackages = p: with p; [
    chex
    ipykernel
    jax
    jaxlib
    joblib
    matplotlib
    numpy
    pandas
    scikit-learn
    scipy
    seaborn
    statsmodels
    tqdm
  ];
in
{
  containers.jupyterhub = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = containerHostAddr;
    localAddress = containerGuestAddr;
    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 8000 ];
      system.stateVersion = config.system.stateVersion;
      services.jupyterhub = {
        enable = true;
        host = containerGuestAddr;
        port = jupyterHubPort;
        kernels = let
          # Python 3.11 blocked on some inscrutable ruamel-yaml build error.
          # Needs Cython >= 0.29.5 -- https://github.com/cython/cython/pull/4428
          # TODO(dwf): Overlay newer Cython.
          customPython = pkgs.python310.override {
            packageOverrides = python-self: python-super: {
              # getfullargspec is removed in Python 3.11.
              bottle = python-super.bottle.overridePythonAttrs {
                src = pkgs.fetchFromGitHub {
                  owner = "bottlepy";
                  repo = "bottle";
                  rev = "0b93489a0b0dfb397838bde584614b44e6040ae5";
                  sha256 = "sha256-AKKK1HnntbvtfZc0pM6s9JUfLu17y+yeFKYhbOSdlyc=";
                };
                doCheck = false;  # Tests try to run servertest.py as a module.
              };
            };
          };
        in {
          python3 = mkPythonKernel rec {
            displayName = "Python ${interpreter.version}";
            interpreter = customPython;
            pkgsFn = mkPythonPackages;
          };
          r = mkRKernel {
            displayName = "R";
            packages = with pkgs.rPackages; [
              dplyr
              ggplot2
              GET
              glmnet
              IRkernel
              tidyverse
            ];
          };
          nix = mkNixKernel { displayName = "Nix"; };
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
