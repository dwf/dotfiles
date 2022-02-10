{
  inputs = {
    home-manager.url = "github:nix-community/home-manager/release-21.11";
  };

  outputs = { self, home-manager }: {
    homeConfigurations = {
      "dwf@skyquake" = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        username = "dwf";
        homeDirectory = "/home/dwf";
        stateVersion = "21.11";
        configuration = import ./home-manager/hosts/skyquake;
      };
    };
  };
}
