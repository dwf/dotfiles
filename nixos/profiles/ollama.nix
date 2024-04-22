# Ollama in a container with ROCm support. Set OLLAMA_HOST=addr:port when
# running ollama outside the container to talk to the container instance.
{
  nixpkgs   # pass a nixpkgs that includes rocmPackages_6, e.g. unstable
, containerHostAddr ? "10.233.10.1"
, containerGuestAddr ? "10.233.10.2"
, autoStart ? true
, devices ? [ "/dev/dri/card0" "/dev/dri/renderD128" ]
, port ? 11434
, ...
}:
{
  containers.ollama = {
    inherit nixpkgs autoStart;
    privateNetwork = true;
    hostAddress = containerHostAddr;
    localAddress = containerGuestAddr;
    allowedDevices = let
      deviceDescr = node: { inherit node; modifier = "rw"; };
    in map deviceDescr devices;
    config = { pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ port ];
      services.ollama = {
        enable = true;
        package = pkgs.ollama.override {
          acceleration = "rocm";
          rocmPackages = pkgs.rocmPackages_6;
        };
        listenAddress = "0.0.0.0:${toString port}";
      };
      system.stateVersion = "24.05";
    };
  };
}
