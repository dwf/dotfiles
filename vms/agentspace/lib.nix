# Shared builder for agentspace microVM sandboxes that boot straight into a
# CLI coding agent. Used by both vms/agentspace/claude and vms/agentspace/agy.
#
# Per-project workspace/history separation doesn't go through eval-time
# `builtins.getEnv`/`nix run --impure`. Instead `workspace`/`meta` below are
# two *fixed* host paths, known once at Nix eval time - a symlink (repointed
# at $PWD) and a one-line tag file. The `wrap` helper below repoints/rewrites
# what's actually at those paths with plain runtime bash immediately before
# each launch, since virtiofsd only reads them fresh at boot.
{
  inputs,
  pkgs,
  system,
}:
{
  # Short name identifying the agent - e.g. "claude", "agy" - used for the
  # state dir, VM persistence dir, and guest script names.
  name,
  # The CLI derivation, e.g. inputs.llm-agents.packages.${system}.claude-code.
  package,
  # Command name `package` puts on $PATH inside the guest, e.g. "claude", "agy".
  binary,
}:
let
  stateDir = "/home/dwf/.local/state/${name}-vm";
  workspaceLink = "${stateDir}/workspace";
  metaDir = "${stateDir}/meta";

  # Guest-side counterpart of the host indirection above: read the tag the
  # wrapper wrote into the `meta` share, bind-mount the `cwd` share onto a
  # directory named after that tag, and cd there. Both agents key --resume
  # history off $PWD, so this is what makes the resume bucket differ per
  # host project. A plain symlink doesn't work: these CLIs resolve cwd via
  # getcwd(), which follows symlinks to their physical target, so every
  # project would collapse onto the same underlying mountpoint.
  cdPreamble = ''
    tag="$(cat "$HOME/workspace/meta/tag")"
    mkdir -p "$HOME/workspace/$tag"
    sudo mount --bind "$HOME/workspace/cwd" "$HOME/workspace/$tag"
    cd "$HOME/workspace/$tag"
  '';

  guestLaunch = pkgs.writeShellScript "agentspace-${name}" (
    cdPreamble
    # No `set -e`: poweroff must run even if the agent exits non-zero.
    # --dangerously-skip-permissions is safe here since the microVM itself
    # is the isolation boundary. Argv is forwarded through verbatim - see
    # `wrap` below, which writes it into meta/args at invocation time.
    + ''
      mapfile -t args < "$HOME/workspace/meta/args"
      ${binary} "''${args[@]}" --dangerously-skip-permissions
      sudo poweroff
    ''
  );

  # Debug shell in the same VM (same overlay/home/mounts) for poking at the guest.
  # Powers off on exit, like the agent target.
  guestShell = pkgs.writeShellScript "agentspace-${name}-shell" (
    cdPreamble
    + ''
      bash -l
      sudo poweroff
    ''
  );

  mkSandboxWith = guestScript: inputs.agentspace.lib.mkSandbox {
    persistence.baseDir = "/home/dwf/vms/agentspace/${name}";

    # TODO: hardcoded to superion - parameterize to support other hosts.
    ssh.authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdP+JZY3fGyoAz1iRO5NVMcc+L43qlrGwhqKoLZfeIq dwf@superion"
    ];
    ssh.autoconnect = true;
    # bash -lc puts nix/sudo on PATH, then execs the store-path script.
    ssh.command = "bash -lc ${guestScript}";

    # addCurrentDir would add a redundant, always-`/mnt/cwd`-mounted share.
    workspace.enable = true;
    workspace.addCurrentDir = false;
    workspace.spaces = {
      cwd = workspaceLink;
      meta = metaDir;
    };

    extraModules = [
      {
        # The agent CLI baked into the guest system: realized once on the
        # host, shared read-only into the VM via the nix-store share, so
        # launches never re-fetch or copy it. Update with
        # `nix flake update llm-agents` then relaunch.
        environment.systemPackages = [ package ];
      }
    ];

    # Share my host git config (name, obfuscated email, aliases, delta) with the
    # guest agent user, so commits made from inside the VM carry the right
    # identity.
    homeModules = [
      inputs.self.homeManagerModules.profiles.git
    ];
  };

  # Host-side prep needed before *any* launch: repoint the fixed `workspace`
  # symlink at $PWD, write a per-project tag into `meta`, and forward argv
  # into `meta/args` for guestLaunch to read back. Baked in here so every
  # entry point gets it, including `nix run .#<name>-vm` directly - it used
  # to skip this prep entirely and fail on an agent's first-ever launch.
  wrap =
    cmdName: rawLaunch:
    pkgs.writeShellScriptBin cmdName ''
      set -euo pipefail
      tag="$(basename "$PWD")-$(printf '%s' "$PWD" | sha256sum | cut -c1-8)"
      mkdir -p "$(dirname ${workspaceLink})" ${metaDir}
      ln -sfn "$PWD" ${workspaceLink}
      printf '%s' "$tag" > ${metaDir}/tag
      printf '%s\n' "$@" > ${metaDir}/args
      exec ${rawLaunch}
    '';
in
{
  inherit workspaceLink metaDir;
  agent = wrap "${name}-vm" (inputs.agentspace.lib.mkLaunch (mkSandboxWith guestLaunch));
  shell = wrap "${name}-vm-shell" (inputs.agentspace.lib.mkLaunch (mkSandboxWith guestShell));
}
