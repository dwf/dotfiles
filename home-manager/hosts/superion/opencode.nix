# opencode (https://opencode.ai) backed by local llama.cpp servers, for
# agentic coding sessions without a cloud API key. Two models, picked for
# different tradeoffs on the same iGPU:
#
# - "glimmer": Meta's Muse Glimmer-30B (distilled from the closed Muse
#   Spark). Dense -- all 30B params active every token -- so on the 780M
#   iGPU's shared LPDDR5x it's memory-bandwidth-bound, not compute-bound:
#   tokens/sec is roughly (memory bandwidth) / (bytes streamed per param),
#   largely independent of the 64GB of RAM headroom here. Decodes around
#   5 tok/s in practice. The heavy option.
# - "gemma4": Google's Gemma 4 26B-A4B, a sparse MoE with only ~4B params
#   active per token despite ~26B total -- same reasoning-quality class as
#   Glimmer's 30B dense, but decode bandwidth cost is set by the ~4B active
#   params, not the full total, so it should feel far more responsive for
#   everyday use. The default model below reflects that: reach for glimmer
#   explicitly when the extra weight is worth the wait.
#
# `mkLocalLlamaService` below is the socket-activation shape both share --
# see ./llama-nes.nix for the systemd-socket-proxyd rationale, which applies
# unchanged to both. It also encodes a lesson learned the hard way getting
# glimmer running: the model fetch (multi-GB) must NOT be inline in
# ExecStartPre, because that gates "start this service" -- systemd's own
# unit-start wait, the socket proxy's on-demand activation, or a plain
# `home-manager switch` restarting a changed unit -- behind a download whose
# duration none of those callers' own (much shorter, independent) timeouts
# can tolerate. Each model instead gets its own oneshot fetch-<id>-model
# unit, run manually once; the real service's ExecStartPre is just a fast
# existence check.
{ pkgs, lib, ... }:
let
  llama-service = import ./llama-service.nix { inherit pkgs lib; };
  mkLlamaService = llama-service.mkLlamaService;
  # Both models are served by the same Vulkan-enabled llama-cpp build,
  # overridden to a newer release than this flake's nixpkgs pin (2026-07-08,
  # llama-cpp b9190): Muse Glimmer support only landed in llama.cpp on
  # 2026-08-10 (PR #26841), after that pin. Gemma 4 has had llama.cpp support
  # since its 2026-04-02 launch -- well within b9190 -- so it doesn't
  # strictly need this override, but reusing one already-validated build for
  # both avoids a second from-source llama.cpp compile for no benefit.
  #
  # Overrides both the package's `src` (pinned to b10437, the newest release
  # as of 2026-08-15, giving 5 days of upstream fixes on top of glimmer's
  # day-0 support) and its `npmDeps` fixed-output derivation: the tools/ui
  # frontend's lockfile hash depends on `src`, and finalAttrs self-references
  # inside the original derivation -- `npmDeps`'s `inherit (finalAttrs)
  # src` -- don't get re-resolved by a plain `overrideAttrs`, so `npmDeps`
  # has to be reconstructed by hand rather than just re-pointing `src`.
  llamaCppVulkanVersion = "10437";
  llamaCppVulkanSrc = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${llamaCppVulkanVersion}";
    hash = "sha256-VuuEUqI1RZjOIiDquLhuz04+bWsCMbOkjYd5XZ9PJyM=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };
  # Vulkan (RADV), not ROCm, for the same reason as llama-nes.nix: the 780M
  # iGPU is gfx1103, off ROCm's officially supported target list.
  llama-cpp-vulkan = (pkgs.llama-cpp.override { vulkanSupport = true; }).overrideAttrs (old: {
    version = llamaCppVulkanVersion;
    src = llamaCppVulkanSrc;
    npmDeps = pkgs.fetchNpmDeps {
      name = "llama-cpp-${llamaCppVulkanVersion}-npm-deps";
      src = llamaCppVulkanSrc;
      patches = [ ];
      preBuild = ''
        pushd tools/ui
      '';
      hash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
    };
    npmDepsHash = "sha256-2Q7XhaLAArmviOLdQsNbYTfdyDE5pW9lR26cRHEVl9k=";
  });

  glimmer = {
    id = "glimmer";
    description = "llama.cpp server (Vulkan) serving Muse Glimmer-30B for opencode";
    modelFilename = "Muse-Glimmer-30B-UD-Q4_K_XL.gguf";
    modelUrl = "https://huggingface.co/unsloth/Muse-Glimmer-30B-GGUF/resolve/main/${glimmer.modelFilename}";
    modelSizeNote = "15.9GB";
    publicPort = 8010;
    backendPort = 8011;
    # UD-Q4_K_XL, not a bigger quant: this is the dense/bandwidth-bound case
    # from the file header, so the smallest reasonable quant maximizes
    # decode speed even though RAM isn't the constraint.
    extraServerArgs = [
      "-c 32768"
      "--temp 1.0"
      "--top-p 0.95"
      "--top-k 64"
    ];
  };

  gemma4 = {
    id = "gemma4";
    description = "llama.cpp server (Vulkan) serving Gemma 4 26B-A4B for opencode";
    modelFilename = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
    modelUrl = "https://huggingface.co/unsloth/gemma-4-26B-A4B-it-GGUF/resolve/main/${gemma4.modelFilename}";
    modelSizeNote = "23.3GB";
    publicPort = 8020;
    backendPort = 8021;
    # UD-Q6_K_XL, not Q4 like glimmer: measured decode here is a flat
    # ~14.5 tok/s regardless of request size (journalctl, 2026-08-15), well
    # under the ~33 tok/s a Q4-bandwidth-only ceiling would predict from
    # glimmer's measured ~80GB/s effective bandwidth scaled to gemma4's ~4B
    # active params. That gap means decode here is compute-bound, not
    # bandwidth-bound like glimmer -- so a bigger quant costs little to no
    # speed while cutting quantization error. Q6, not Q8, as a middle ground
    # without measurements at Q6 itself yet.
    #
    # Sampling params are Google's documented defaults for Gemma 4. Thinking
    # mode is left at template default (not force-enabled via
    # --chat-template-kwargs '{"enable_thinking":true}') -- this model's job
    # here is to be the fast, responsive option next to glimmer's heavier
    # reasoning mode, and forcing thinking on would work against that.
    extraServerArgs = [
      "-c 32768"
      "--temp 1.0"
      "--top-p 0.95"
      "--top-k 64"
    ];
  };

  mkOpencodeProvider = name: model: {
    npm = "@ai-sdk/openai-compatible";
    inherit name;
    options = {
      baseURL = "http://127.0.0.1:${toString model.publicPort}/v1";
      apiKey = "local";
    };
    models.${model.id} = {
      inherit name;
      limit = {
        context = 32768;
        output = 8192;
      };
    };
  };
in
lib.mkMerge [
  {
    home.packages = [ pkgs.opencode ];

    # opencode's own config discovery (XDG_CONFIG_HOME/opencode/opencode.json)
    # -- see https://opencode.ai/docs. Provider id matches each model's `id`
    # above, which also matches the --alias passed to llama-server.
    home.file.".config/opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      provider = {
        glimmer = mkOpencodeProvider "Muse Glimmer 30B (local)" glimmer;
        gemma4 = mkOpencodeProvider "Gemma 4 26B-A4B (local)" gemma4;
      };
      # gemma4, not glimmer, as the default: MoE decode speed makes it the
      # sane everyday choice (see file header). Switch explicitly in
      # opencode when glimmer's extra weight is worth the wait.
      model = "gemma4/gemma4";
    };
  }
  (mkLlamaService {
    inherit (glimmer) id description modelFilename modelUrl modelSizeNote publicPort backendPort extraServerArgs;
    llamaCppPackage = llama-cpp-vulkan;
  })
  (mkLlamaService {
    inherit (gemma4) id description modelFilename modelUrl modelSizeNote publicPort backendPort extraServerArgs;
    llamaCppPackage = llama-cpp-vulkan;
  })
]
