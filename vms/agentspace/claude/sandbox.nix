# Claude Code instantiation of the shared agentspace sandbox builder
# (../lib.nix), used by both the flake apps (./apps.nix, `nix run
# .#claude-vm`) and the home-manager `claude-vm` PATH wrapper (./wrappers.nix).
{
  inputs,
  pkgs,
  system,
}:
import ../lib.nix { inherit inputs pkgs system; } {
  name = "claude";
  package = inputs.llm-agents.packages.${system}.claude-code;
  binary = "claude";
}
