# Ollama in a container with ROCm support. Set OLLAMA_HOST=addr:port when
# running ollama outside the container to talk to the container instance.
{
  nixpkgs,
  hostAddress ? "10.233.10.1",
  localAddress ? "10.233.10.2",
  autoStart ? true,
  devices ? [
    "/dev/dri/card0"
    "/dev/kfd"
    "/dev/dri/renderD128" # seems to only really need this one
  ],
  port ? 11434,
  ...
}:
{
  containers.ollama = {
    inherit
      nixpkgs
      autoStart
      hostAddress
      localAddress
      ;
    privateNetwork = true;
    allowedDevices =
      let
        deviceDescr = node: {
          inherit node;
          modifier = "rw";
        };
      in
      map deviceDescr devices;
    bindMounts = (nixpkgs.lib.genAttrs devices (_: { })) // {
      "/sys/module".isReadOnly = true;
    };
    config = {
      networking.firewall.allowedTCPPorts = [ port ];

      # Strangely, package = pkgs.ollama.override { ... } didn't work
      # inside the container, but rocmPackages is already set to
      # rocmPackages_6.
      services.ollama = {
        enable = true;
        acceleration = "rocm";
        listenAddress = "0.0.0.0:${toString port}";
      };
      system.stateVersion = "24.05";
    };
  };
}
