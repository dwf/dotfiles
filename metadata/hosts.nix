# Per-host metadata keyed by networking.hostName. Used to generalize things
# that used to be hardcoded to one machine, e.g. nixos/profiles/global.nix's
# authorizedKeys and vms/agentspace/lib.nix's guest ssh.authorizedKeys.
{
  superion.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdP+JZY3fGyoAz1iRO5NVMcc+L43qlrGwhqKoLZfeIq";
  wheeljack.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMfMWW0Aoj1n1vyN6tKV6vobg6XjDsoSaDGGzF+qjyPO";
  soundwave.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICE57KT7QbABAqFvunur9tYnMHSmr6NbzMvVMVMLgv/+";
}
