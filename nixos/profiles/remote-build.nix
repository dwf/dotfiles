# Add a user specifically for remote builds.
{ config, ... }:
{
  users.users.nix-remote-build = {
    isNormalUser = true;
    openssh.authorizedKeys = config.users.users.dwf.openssh.authorizedKeys;
  };
  nix.trustedUsers = [ "nix-remote-build" ];
}
