{ pkgs, lib, ... }:
let
  # The common socket-activation quad (fetch unit, check-then-serve unit, proxy unit +
  # socket) for a local llama.cpp server.
  #
  # This pattern uses systemd-socket-proxyd to bridge a public port to a backend
  # llama-server port. This allows the service to be socket-activated and,
  # more importantly, allows the llama-server to exit when the proxy is idle,
  # which releases the Vulkan context and allows the iGPU to power down.
  mkLlamaService =
    {
      id,
      description,
      modelFilename,
      modelUrl,
      modelSizeNote,
      publicPort,
      backendPort,
      llamaCppPackage,
      extraServerArgs ? [ ],
      idleTimeout ? "30min",
    }:
    {
      systemd.user.sockets."llama-server-${id}-proxy" = {
        Install.WantedBy = [ "sockets.target" ];
        Socket.ListenStream = "127.0.0.1:${toString publicPort}";
      };

      systemd.user.services."llama-server-${id}-proxy" = {
        Unit = {
          Description = "Socket-activation proxy for llama-server-${id}";
          Requires = [ "llama-server-${id}.service" ];
          After = [ "llama-server-${id}.service" ];
        };
        Service.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=${idleTimeout} 127.0.0.1:${toString backendPort}";
      };

      systemd.user.services."fetch-${id}-model" = {
        Unit.Description = "Fetch the model for llama-server-${id}";
        Service = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "fetch-${id}-model" ''
            set -euo pipefail
            dest="$HOME/.cache/llama-cpp-models/${modelFilename}"
            mkdir -p "$(dirname "$dest")"
            if [ ! -s "$dest" ]; then
              ${pkgs.curl}/bin/curl -fL -C - --speed-limit 1000 --speed-time 30 \
                -o "$dest.tmp" "${modelUrl}"
              mv "$dest.tmp" "$dest"
            fi
          '';
        };
      };

      systemd.user.services."llama-server-${id}" = {
        Unit = {
          Description = description;
          StopWhenUnneeded = true;
        };
        Service = {
          ExecStartPre = pkgs.writeShellScript "check-${id}-model" ''
            set -euo pipefail
            dest="$HOME/.cache/llama-cpp-models/${modelFilename}"
            if [ ! -s "$dest" ]; then
              echo "Model not found at $dest -- run 'systemctl --user start fetch-${id}-model.service' first (${modelSizeNote}, run manually so it's not gated behind a service-start timeout)." >&2
              exit 1
            fi
          '';
          ExecStart = ''
            ${llamaCppPackage}/bin/llama-server \
              --model %h/.cache/llama-cpp-models/${modelFilename} \
              --alias ${id} \
              --host 127.0.0.1 --port ${toString backendPort} \
              -ngl 99 -fa on --jinja \
              ${lib.concatStringsSep " " extraServerArgs}
          '';
          Restart = "on-failure";
          RestartSec = 5;
        };
      };
    };
in
{
  inherit mkLlamaService;
}
