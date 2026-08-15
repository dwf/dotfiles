# opencode (https://opencode.ai) backed by a local llama.cpp server serving
# Meta's Muse Glimmer-30B (the open-weight model distilled from the closed
# Muse Spark), for agentic coding sessions without a cloud API key.
#
# Same socket-activation shape as ./llama-nes.nix -- see that file for the
# systemd-socket-proxyd rationale, which applies unchanged here. Two things
# differ enough to be worth calling out:
#
# - Muse Glimmer support only landed in llama.cpp on 2026-08-10 (PR #26841),
#   after this flake's nixpkgs pin (2026-07-08, llama-cpp b9190) and likely
#   still ahead of whenever nixpkgs next bumps its own llama-cpp version.
#   `llama-cpp-glimmer` below overrides both the package's `src` (pinned to
#   b10437, the newest release as of 2026-08-15, giving 5 days of upstream
#   fixes on top of day-0 support) and its `npmDeps` fixed-output derivation
#   (the tools/ui frontend's lockfile hash depends on `src`, and finalAttrs
#   self-references inside the original derivation -- `npmDeps`'s `inherit
#   (finalAttrs) src` -- don't get re-resolved by a plain `overrideAttrs`, so
#   `npmDeps` has to be reconstructed by hand rather than just re-pointing
#   `src`). This is a 5-day-old backend for a 5-day-old model architecture:
#   expect rough edges Vulkan-specific bugs haven't shaken out yet.
# - Muse Glimmer is a dense 30B model (all params active every token, unlike
#   an MoE), so unlike NES's 1.5B model it's memory-bandwidth-bound on the
#   780M iGPU's shared LPDDR5x, not compute-bound: tokens/sec is roughly
#   (memory bandwidth) / (bytes streamed per param), largely independent of
#   the 64GB of RAM headroom on this machine. That's why this picks the
#   UD-Q4_K_XL quant (15.9GB) over a larger one -- superion has RAM to spare
#   for a bigger quant, but not the bandwidth to make it worth the slowdown.
{ pkgs, ... }:
let
  glimmerLlamaCppVersion = "10437";
  glimmerLlamaCppSrc = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${glimmerLlamaCppVersion}";
    hash = "sha256-VuuEUqI1RZjOIiDquLhuz04+bWsCMbOkjYd5XZ9PJyM=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };
  # Vulkan (RADV), not ROCm, for the same reason as llama-nes.nix: the 780M
  # iGPU is gfx1103, off ROCm's officially supported target list.
  llama-cpp-glimmer = (pkgs.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (old: {
    version = glimmerLlamaCppVersion;
    src = glimmerLlamaCppSrc;
    npmDeps = pkgs.fetchNpmDeps {
      name = "llama-cpp-${glimmerLlamaCppVersion}-npm-deps";
      src = glimmerLlamaCppSrc;
      patches = [ ];
      preBuild = ''
        pushd tools/ui
      '';
      hash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
    };
    npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
  });

  modelFilename = "Muse-Glimmer-30B-UD-Q4_K_XL.gguf";
  modelUrl = "https://huggingface.co/unsloth/Muse-Glimmer-30B-GGUF/resolve/main/${modelFilename}";

  publicPort = 8010;
  backendPort = 8011;
in
{
  home.packages = [ pkgs.opencode ];

  # opencode's own config discovery (XDG_CONFIG_HOME/opencode/opencode.json)
  # -- see https://opencode.ai/docs. Provider id and model id both "glimmer"
  # to match the --alias passed to llama-server below.
  home.file.".config/opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider.glimmer = {
      npm = "@ai-sdk/openai-compatible";
      name = "Muse Glimmer 30B (local)";
      options = {
        baseURL = "http://127.0.0.1:${toString publicPort}/v1";
        apiKey = "local";
      };
      models.glimmer = {
        name = "Muse Glimmer 30B (local)";
        limit = {
          context = 32768;
          output = 8192;
        };
      };
    };
    model = "glimmer/glimmer";
  };

  systemd.user.sockets.llama-server-glimmer-proxy = {
    Install.WantedBy = [ "sockets.target" ];
    Socket.ListenStream = "127.0.0.1:${toString publicPort}";
  };

  systemd.user.services.llama-server-glimmer-proxy = {
    Unit = {
      Description = "Socket-activation proxy for llama-server-glimmer";
      Requires = [ "llama-server-glimmer.service" ];
      After = [ "llama-server-glimmer.service" ];
    };
    # Longer idle timeout than NES's 5min: an agentic coding session has much
    # longer natural gaps (reading output, thinking, editing) than inline
    # ghost-text typing does, and reloading 15.9GB into the iGPU on every gap
    # costs a lot more than NES's 1.5GB model does.
    Service.ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=30min 127.0.0.1:${toString backendPort}";
  };

  systemd.user.services.llama-server-glimmer = {
    Unit = {
      Description = "llama.cpp server (Vulkan) serving Muse Glimmer-30B for opencode";
      StopWhenUnneeded = true;
    };
    Service = {
      # NES's model is 1.5GB and fetches well within systemd's default
      # 90s DefaultTimeoutStartSec; this one is 15.9GB and does not, so the
      # unbounded default here previously meant systemd killed ExecStartPre
      # mid-download at the 90s mark every time, and Restart=on-failure kept
      # retrying the fetch from scratch forever. --speed-limit/--speed-time
      # below still fails out (rather than hanging forever) if the transfer
      # genuinely stalls.
      TimeoutStartSec = "infinity";
      # Same rationale as llama-nes.nix: fetched into ~/.cache rather than
      # pinned via pkgs.fetchurl, since this nixpkgs' llama-cpp has no curl
      # support built in and ~/.cache is prunable, unlike a permanent 16GB
      # nix store item.
      ExecStartPre = pkgs.writeShellScript "fetch-glimmer-model" ''
        set -euo pipefail
        dest="$HOME/.cache/llama-cpp-models/${modelFilename}"
        mkdir -p "$(dirname "$dest")"
        if [ ! -s "$dest" ]; then
          ${pkgs.curl}/bin/curl -fL -C - --speed-limit 1000 --speed-time 30 \
            -o "$dest.tmp" "${modelUrl}"
          mv "$dest.tmp" "$dest"
        fi
      '';
      ExecStart = ''
        ${llama-cpp-glimmer}/bin/llama-server \
          --model %h/.cache/llama-cpp-models/${modelFilename} \
          --alias glimmer \
          --host 127.0.0.1 --port ${toString backendPort} \
          -ngl 99 -c 32768 \
          --jinja \
          --temp 1.0 --top-p 0.95 --top-k 64
      '';
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
