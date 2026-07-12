# Shared agentspace sandbox definition for Claude Code, used by both the flake
# apps (./apps.nix, `nix run .#claude-vm`) and the home-manager `claude-vm` PATH
# wrapper (./wrappers.nix). Pulled out so both build the exact same derivation
# instead of the wrapper re-evaluating the flake at launch time.
#
# Per-project workspace/history separation used to be done by reading the
# launch-time cwd via `builtins.getEnv "AGENTSPACE_CWD"` at Nix eval time,
# which forced every launch through `nix run --impure`. Instead, `workspace`
# and `meta` below are two *fixed* host paths, known once at eval time (fully
# pure) - a symlink (repointed at $PWD) and a one-line tag file. The
# `claude-vm` wrapper (wrappers.nix) repoints/rewrites what's actually *at*
# those paths with plain runtime bash immediately before each launch;
# virtiofsd only reads them when the microVM boots, which happens fresh per
# launch, well after this derivation was built. So a single pre-built,
# cacheable launch program ends up sharing whatever project the wrapper most
# recently pointed it at. (The guest-side use of these two shares is a bind
# mount, not a symlink - see cdPreamble below for why.)
{
  inputs,
  pkgs,
  system,
}:
let
  stateDir = "/home/dwf/.local/state/claude-vm";
  workspaceLink = "${stateDir}/workspace";
  metaDir = "${stateDir}/meta";

  # Guest-side counterpart of the host indirection above: read the tag the
  # wrapper wrote into the `meta` share, bind-mount the `cwd` share onto a
  # directory named after that tag, and cd there. Claude keys --resume
  # history off $PWD (every non-alphanumeric char mapped to '-'), so this is
  # what makes the guest cwd - and thus the resume bucket - differ per host
  # project.
  #
  # A symlink doesn't work here: (1) if $HOME/workspace/$tag already exists
  # as a real directory (e.g. left over from a previous boot), `ln -sfn`
  # nests the symlink *inside* it instead of replacing it, silently cd-ing
  # into the wrong, near-empty directory; (2) even placed correctly, `claude`
  # (Node) determines its cwd via `process.cwd()`/getcwd(), which resolves
  # symlinks to their physical target - so every project would still
  # collapse onto the same underlying `cwd` mountpoint for resume-bucketing
  # purposes. A bind mount is a real mountpoint at the tag path, immune to
  # both.
  cdPreamble = ''
    tag="$(cat "$HOME/workspace/meta/tag")"
    mkdir -p "$HOME/workspace/$tag"
    sudo mount --bind "$HOME/workspace/cwd" "$HOME/workspace/$tag"
    cd "$HOME/workspace/$tag"
  '';

  guestLaunch = pkgs.writeShellScript "agentspace-claude" (
    cdPreamble
    # No `set -e`: poweroff must run even if Claude exits non-zero, to honour
    # shutdown-on-disconnect.
    # --dangerously-skip-permissions: the microVM is the isolation boundary, so
    # no per-action prompts inside it. Safe because the guest runs Claude as the
    # unprivileged `agent` user, not root.
    # Whatever `claude-vm` was actually invoked with (e.g. `claude-vm --resume`,
    # `--continue`, a search term, nothing) gets written newline-separated into
    # the `meta` share's `args` file at wrapper-invocation time (see
    # wrappers.nix) - read it back here and pass it straight through, rather
    # than trying to guess whether resumable history exists.
    + ''
      mapfile -t args < "$HOME/workspace/meta/args"
      claude "''${args[@]}" --dangerously-skip-permissions
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

    # Both shares are fixed, eval-time-known strings (see header comment) -
    # `addCurrentDir` is explicitly disabled since it would add a redundant,
    # always-`/mnt/cwd`-mounted share we no longer use.
    workspace.enable = true;
    workspace.addCurrentDir = false;
    workspace.spaces = {
      cwd = workspaceLink;
      meta = metaDir;
    };

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
  inherit workspaceLink metaDir;
  claude = inputs.agentspace.lib.mkLaunch (mkSandboxWith guestLaunch);
  shell = inputs.agentspace.lib.mkLaunch (mkSandboxWith guestShell);
}
