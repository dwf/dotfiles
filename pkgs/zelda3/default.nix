{ pkgs, ... }:
let
  version = "2025-12-26";
  src = pkgs.fetchFromGitHub {
    owner = "snesrev";
    repo = "zelda3";
    rev = "fbbb3f967a51fafe642e6140d0753979e73b4090";
    hash = "sha256-oMSjTLPOWacOyQg5kZUPMZm3ciJGfteqbhNxFJD+2Xg=";
  };
  zelda3-sfc = pkgs.requireFile {
    name = "zelda3.sfc";
    message = "Obtain the USA region Zelda 3 ROM, name it zelda3.sfc and add it to the nix store manually with: nix store add-file ./zelda3.sfc";
    sha256 = "sha256-ZocdZr4ZrSw0ySfWsUzY62/DGBlltuUXyzYfcxYAnPs=";
  };
in
rec {
  zelda3-assets = pkgs.stdenv.mkDerivation {
    name = "zelda3-assets";
    inherit src version;
    nativeBuildInputs = with pkgs; [
      (python3.withPackages (
        p: with p; [
          pillow
          pyyaml
        ]
      ))
    ];
    buildPhase = ''
      # Don't run make, as top-level defs try to run sdl2-config which is unneeded for this.
      python assets/restool.py --extract-from-rom --rom ${zelda3-sfc}
    '';
    installPhase = "mkdir -p $out && cp zelda3_assets.dat $out/";
  };
  zelda3-unwrapped = pkgs.stdenv.mkDerivation {
    name = "zelda3";
    inherit src version;
    nativeBuildInputs = [ pkgs.SDL2 ];
    patches = [
      ./3-2-aspect.patch # Add support for 3:2 aspect ratio, for the Framework 13 & RG34XX[SP]
      ./env-vars.patch # Allow specification of state and asset location with ZELDA3_{ASSETS,STATE}
    ];
    buildPhase = ''
      # BUild only the zelda3 binary target: don't run asset extraction.
      make zelda3
    '';
    installPhase = ''
      mkdir -p $out/share/zelda3
      cp zelda3.ini $out/share/zelda3
      mkdir -p $out/bin
      cp ./zelda3 $out/bin/.zelda3-unwrapped
    '';
  };
  zelda3 = pkgs.writeShellScriptBin "zelda3" ''
    CONFIG=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        --config)
          if [[ -n "$2" && "$2" != -* ]]; then
            CONFIG="$2"
            shift 2
          else
            echo "Error: Argument for --config is missing" >&2
            exit 1
          fi
          ;;
        --help)
          echo "Usage: $0 [--config value]"
          exit 0
          ;;
        *) # Preserve positional arguments
          echo "Unknown option: $1"
          exit 1
          ;;
      esac
    done
    if [ -z "$CONFIG" ]; then
      if [ -e "$HOME/.config/zelda3/zelda3.ini" ]; then
        CONFIG="$HOME/.config/zelda3/zelda3.ini"
      else
        CONFIG="${zelda3-unwrapped}/share/zelda3/zelda3.ini"
      fi
    fi
    echo "Using config file: $CONFIG"
    mkdir -p "$HOME/.local/share/zelda3"
    if [ -z "$ZELDA3_ASSETS" ]; then
      export ZELDA3_ASSETS="${zelda3-assets}"
    else
      echo "Using specified assets dir: $ZELDA3_ASSETS"
    fi
    if [ -z "$ZELDA3_STATE" ]; then
      export ZELDA3_STATE="$HOME/.local/share/zelda3"
    else
      echo "Using specified state dir: $ZELDA3_STATE"
    fi
    [ \! -d "$ZELDA3_STATE" ] && mkdir -p "$ZELDA3_STATE"
    ${zelda3-unwrapped}/bin/.zelda3-unwrapped --config "$CONFIG"
  '';
}
