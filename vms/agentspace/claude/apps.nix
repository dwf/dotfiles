# `nix run .#claude-vm` boots into Claude Code on the launch-time cwd;
# `.#claude-vm-shell` drops to a debug shell in the same VM. Imported and
# applied by flake.nix; the `claude-vm` PATH wrapper lives alongside in
# ./wrappers.nix.
{
  inputs,
  pkgs,
  system,
}:
let
  # Impure: the launch-time host cwd, injected by the `claude-vm` wrapper via
  # AGENTSPACE_CWD. Empty in pure eval (`nix run .#claude-vm`, `nix flake check`),
  # which falls back to a fixed /mnt/cwd mount.
  hostCwd = builtins.getEnv "AGENTSPACE_CWD";
  perProject = hostCwd != "";
  tag = "${baseNameOf hostCwd}-${builtins.substring 0 8 (builtins.hashString "sha256" hostCwd)}";

  # Shared preamble: cd into the mounted cwd. Per-project mounts at a hashed path;
  # the pure fallback lands in shared /mnt/cwd and warns.
  cdPreamble =
    if perProject then
      ''
        cd "$HOME/workspace/${tag}"
      ''
    else
      ''
        printf '\033[1;33m%s\033[0m\n' "agentspace: launched without per-project context (pure eval / no wrapper)."
        printf '\033[33m%s\033[0m\n'   "All projects share the /mnt/cwd session-history bucket, so --resume mixes them."
        printf '\033[33m%s\033[0m\n'   "Launch via the 'claude-vm' command for per-project --resume history."
        echo
        cd /mnt/cwd
      '';

  guestLaunch = pkgs.writeShellScript "agentspace-claude" (
    cdPreamble
    # No `set -e`: poweroff must run even if Claude exits non-zero, to honour
    # shutdown-on-disconnect.
    # --dangerously-skip-permissions: the microVM is the isolation boundary, so
    # no per-action prompts inside it. Safe because the guest runs Claude as the
    # unprivileged `agent` user, not root.
    # Only pass --resume when this cwd has saved sessions, else it just shows an
    # empty picker. Claude keys history by cwd with every non-alphanumeric char
    # mapped to '-' (verified against the host's ~/.claude/projects). $PWD here is
    # post-cd, matching Claude's own. Pure-bash param expansion (no `sed`) so the
    # only external commands are ones we want from the guest: claude, sudo,
    # poweroff.
    + ''
      proj="$HOME/.claude/projects/''${PWD//[^a-zA-Z0-9]/-}"
      resume=()
      if compgen -G "$proj/*.jsonl" > /dev/null 2>&1; then
        resume=(--resume)
      fi
      claude "''${resume[@]}" --dangerously-skip-permissions
      sudo poweroff
    ''
  );

  # Debug shell in the same VM (same overlay/home/mounts) for poking at the guest.
  # Powers off on exit, like the Claude target.
  guestShell = pkgs.writeShellScript "agentspace-shell" (
    cdPreamble
    + ''
      bash -l
      sudo poweroff
    ''
  );

  mkSandboxWith = guestScript: inputs.agentspace.lib.mkSandbox {
    persistence.baseDir = "/home/dwf/vms/agentspace/claude";

    # TODO: hardcoded to superion - parameterize to support other hosts.
    ssh.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdP+JZY3fGyoAz1iRO5NVMcc+L43qlrGwhqKoLZfeIq dwf@superion"
    ];
    ssh.autoconnect = true;
    # bash -lc puts nix/sudo on PATH, then execs the store-path script.
    ssh.command = "bash -lc ${guestScript}";

    workspace.enable = true;
    # per-project: mount cwd at a hashed path (eval-time, impure).
    # fallback:    dynamic $PWD -> /mnt/cwd (launch-time, pure-safe).
    workspace.addCurrentDir = !perProject;
    workspace.spaces = if perProject then { "${tag}" = hostCwd; } else { };

    extraModules = [
      {
        # Claude Code baked into the guest system: realized once on the host,
        # shared read-only into the VM via the nix-store share, so launches never
        # re-fetch or copy it. `claude` is on $PATH. Update with
        # `nix flake update llm-agents` then relaunch.
        environment.systemPackages = [
          inputs.llm-agents.packages.${system}.claude-code
        ];
      }
    ];

    # Share my host git config (name, obfuscated email, aliases, delta) with the
    # guest agent user, so commits made from inside the VM carry the right
    # identity.
    homeModules = [
      inputs.self.homeManagerModules.profiles.git
    ];
  };
in
{
  claude-vm = {
    type = "app";
    program = inputs.agentspace.lib.mkLaunch (mkSandboxWith guestLaunch);
  };
  claude-vm-shell = {
    type = "app";
    program = inputs.agentspace.lib.mkLaunch (mkSandboxWith guestShell);
  };
}
