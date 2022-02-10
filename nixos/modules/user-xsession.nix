# Adds (but does not activate) a display manager session which simply invokes
# a user's ~/.xsession file, which can then be manually written or configured
# via home-manager.
{
  services.xserver.displayManager.session = [
    {
      manage = "desktop";
      name = "user-xsession";
      start = ''exec $HOME/.xsession'';
    }
  ];
}
