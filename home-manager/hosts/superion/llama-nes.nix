# Local llama.cpp server for blink-edit.nvim's next-edit-suggestion feature
# (see ../../../neovim/plugins/blink-edit.nix). Built with the Vulkan backend
# rather than ROCm: this laptop's Radeon 780M iGPU is gfx1103, which isn't on
# ROCm's officially supported target list, while llama.cpp's Vulkan (RADV)
# backend works on any RDNA3 iGPU with no override needed.
#
# home-manager's systemd.user.services/sockets is a thin freeform passthrough
# to raw INI sections (Unit/Service/Socket/Install, capitalized systemd
# directive names) rather than NixOS's wantedBy/requires/serviceConfig
# convenience wrappers -- deployed via `home-manager switch`, not
# `nixos-rebuild switch`.
{ pkgs, ... }:
let
  llama-cpp-vulkan = pkgs.llama-cpp.override { vulkanSupport = true; };
  modelFilename = "sweep-next-edit-1.5b.q8_0.v2.gguf";
  modelUrl = "https://huggingface.co/sweepai/sweep-next-edit-1.5B/resolve/main/${modelFilename}";
in
{
  # Socket-activated rather than always-on: llama-server holds an active
  # Vulkan context the whole time it's running, which can keep the 780M iGPU
  # from dropping into its lowest power state even fully idle (no requests) -
  # a real battery-drain concern on a laptop, unlike the ~1.5GB of RAM/VRAM it
  # holds. llama-server itself has no systemd socket-activation support (it
  # binds its own socket, doesn't call sd_listen_fds), so systemd-socket-proxyd
  # (shipped in nixpkgs' systemd) bridges: it owns the public port (8000) via
  # socket activation, forwards to the real llama-server on a second,
  # non-activatable port (8001), and pulls the backend up via Requires/After
  # when the proxy itself starts. StopWhenUnneeded on the backend lets it exit
  # once the proxy (which self-exits after its own idle timeout) stops
  # needing it, so the Vulkan context only exists while something is actively
  # using NES.
  systemd.user.sockets.llama-server-nes-proxy = {
    Install.WantedBy = [ "sockets.target" ];
    Socket.ListenStream = "127.0.0.1:8000";
  };

  systemd.user.services.llama-server-nes-proxy = {
    Unit = {
      Description = "Socket-activation proxy for llama-server-nes";
      Requires = [ "llama-server-nes.service" ];
      After = [ "llama-server-nes.service" ];
    };
    Service.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:8001";
  };

  systemd.user.services.llama-server-nes = {
    Unit = {
      Description = "llama.cpp server (Vulkan) serving Sweep Next-Edit for blink-edit.nvim";
      # Not WantedBy anything: only started transitively, via the proxy
      # socket's Requires= above, and stopped again per StopWhenUnneeded.
      StopWhenUnneeded = true;
    };
    Service = {
      # Fetched into a plain cache dir rather than pinned via pkgs.fetchurl:
      # this nixpkgs' llama-cpp has no curl support built in (so
      # `llama-server -hf ...` can't self-fetch), and unlike a nix store
      # path, ~/.cache is prunable, avoiding a permanent 1.4GB store item.
      # Same approach ../../../nixos/profiles/ollama.nix's models take.
      #
      # $HOME, not %h, in this script: %h is a systemd unit-file specifier,
      # only expanded when it appears directly in a directive's value (as in
      # ExecStart below) -- not inside the contents of a script a directive
      # merely invokes by path. Using %h here would create a literal `%h`
      # directory instead of expanding to the real home directory.
      ExecStartPre = pkgs.writeShellScript "fetch-sweep-nes-model" ''
        set -euo pipefail
        dest="$HOME/.cache/llama-cpp-models/${modelFilename}"
        mkdir -p "$(dirname "$dest")"
        if [ ! -s "$dest" ]; then
          ${pkgs.curl}/bin/curl -fL -o "$dest.tmp" "${modelUrl}"
          mv "$dest.tmp" "$dest"
        fi
      '';
      ExecStart = ''
        ${llama-cpp-vulkan}/bin/llama-server \
          --model %h/.cache/llama-cpp-models/${modelFilename} \
          --alias sweep \
          --host 127.0.0.1 --port 8001 \
          -ngl 99 -c 8192
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
