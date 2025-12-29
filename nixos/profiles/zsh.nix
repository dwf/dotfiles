{ lib, ... }:
{
  # Allows home-manager installed shells to be the login shell.
  environment = {
    etc."shells".text = lib.mkAfter ''
      /home/dwf/.nix-profile/bin/zsh
    '';

    # For completion of system packages.
    pathsToLink = [ "/share/zsh" ];
  };

  # Set my default login shell to home-manager-installed zsh.
  users.users.dwf = {
    useDefaultShell = false;
    shell = "/home/dwf/.nix-profile/bin/zsh";
  };
}
