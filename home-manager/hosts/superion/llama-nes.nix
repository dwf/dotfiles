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
{ pkgs, lib, ... }:
let
  llama-service = import ./llama-service.nix { inherit pkgs lib; };
  mkLlamaService = llama-service.mkLlamaService;
  llama-cpp-vulkan = pkgs.llama-cpp.override { vulkanSupport = true; };
  modelFilename = "sweep-next-edit-1.5b.q8_0.v2.gguf";
  modelUrl = "https://huggingface.co/sweepai/sweep-next-edit-1.5B/resolve/main/${modelFilename}";
in
lib.mkMerge [
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
  (mkLlamaService {
    id = "nes";
    description = "llama.cpp server (Vulkan) serving Sweep Next-Edit for blink-edit.nvim";
    modelFilename = modelFilename;
    modelUrl = modelUrl;
    modelSizeNote = "1.4GB";
    publicPort = 8000;
    backendPort = 8001;
    llamaCppPackage = llama-cpp-vulkan;
    extraServerArgs = [ "-c 8192" ];
    idleTimeout = "5min";
  })
]
