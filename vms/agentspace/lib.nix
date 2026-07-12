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
  # The invoking host's name, so the guest ssh.authorizedKeys can be looked
  # up per host instead of hardcoded - see authorizedKeys below. May or may
  # not include a domain suffix - only the first dot-separated token matters.
  hostName,
  # If hostName has no metadata/hosts.nix entry, fall back to trusting
  # whatever *.pub key(s) are in the invoking user's ~/.ssh instead of
  # throwing - see authorizedKeys below. Only vms/agentspace/*/apps.nix (the
  # `nix run .#<name>-vm` flake app, not tied to a real host) sets this;
  # the claude-vm/agy-vm PATH wrappers leave it off so a typo'd/unregistered
  # real hostName still fails loudly instead of silently trusting the wrong
  # key.
  allowImpureSshKeyFallback ? false,
}:
{
  # Short name identifying the agent - e.g. "claude", "agy" - used for the
  # state dir, VM persistence dir, and guest script names.
  name,
  # The CLI derivation, e.g. inputs.llm-agents.packages.${system}.claude-code.
  package,
  # Command name `package` puts on $PATH inside the guest, e.g. "claude", "agy".
  binary,
  # Guest $HOME-relative path where ./AGENTS.md gets symlinked - varies per
  # agent (e.g. Claude Code reads ~/.claude/CLAUDE.md, antigravity-cli reads
  # ~/.gemini/antigravity-cli/AGENTS.md).
  agentsFilePath,
}:
let
  hosts = import ../../metadata/hosts.nix;
  bareHostName = builtins.head (pkgs.lib.splitString "." hostName);
  authorizedKeys =
    if hosts ? ${bareHostName} then
      [ hosts.${bareHostName}.publicKey ]
    else if allowImpureSshKeyFallback then
      # builtins.getEnv only returns the real $HOME under --impure (it's ""
      # otherwise); builtins.readDir/readFile on the resulting absolute path
      # then throw Nix's own loud "forbidden in pure evaluation mode" error
      # if --impure wasn't passed, before we even get to our own checks.
      let
        sshDir = "${builtins.getEnv "HOME"}/.ssh";
        pubKeyFiles = builtins.filter (pkgs.lib.hasSuffix ".pub") (
          builtins.attrNames (builtins.readDir sshDir)
        );
      in
      if pubKeyFiles == [ ] then
        throw "vms/agentspace/lib.nix: no *.pub files found under ${sshDir} - make sure you have an SSH keypair there."
      else
        map (f: pkgs.lib.removeSuffix "\n" (builtins.readFile "${sshDir}/${f}")) pubKeyFiles
    else
      throw "vms/agentspace/lib.nix: no metadata/hosts.nix entry for host '${bareHostName}' - add one.";

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

    # Reuse the host's persistent, socket-activated virtiofsd for the
    # read-only /nix/store share (agentspace.hostVirtiofsdNixStore) instead
    # of having virtie spin up a fresh one per launch.
    nixStoreShareSocket = "/run/virtiofs-nix-store.sock";

    ssh = {
      inherit authorizedKeys;
      autoconnect = true;
      # bash -lc puts nix/sudo on PATH, then execs the store-path script.
      command = "bash -lc ${guestScript}";
    };

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
      {
        # Doesn't change per launch, so a plain nix-store symlink (rather
        # than the runtime workspace/meta bind-mount machinery above) is
        # fine - home-manager activation sets this up once, baked into the
        # guest closure.
        home.file.${agentsFilePath}.source = ./AGENTS.md;
      }
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
