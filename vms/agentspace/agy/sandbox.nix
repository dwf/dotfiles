# antigravity-cli (`agy`) instantiation of the shared agentspace sandbox
# builder (../lib.nix), used by both the flake apps (./apps.nix, `nix run
# .#agy-vm`) and the home-manager `agy-vm` PATH wrapper (./wrappers.nix).
{
  inputs,
  pkgs,
  system,
  hostName,
  allowImpureSshKeyFallback ? false,
}:
import ../lib.nix { inherit inputs pkgs system hostName allowImpureSshKeyFallback; } {
  name = "agy";
  package = inputs.llm-agents.packages.${system}.antigravity-cli;
  binary = "agy";
}
