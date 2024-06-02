{
  programs.keychain = {
    enable = true;
    enableBashIntegration = true;
    enableXsessionIntegration = true;
    agents = [ "ssh" ];
    keys = [ "id_ed25519" ];
  };
}
