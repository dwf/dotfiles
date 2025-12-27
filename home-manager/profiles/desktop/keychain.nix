{
  programs.keychain = {
    enable = true;
    enableBashIntegration = true;
    enableXsessionIntegration = true;
    keys = [ "id_ed25519" ];
  };
}
