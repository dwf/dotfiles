{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager }: {
    homeConfigurations = {
      "dwf@skyquake" = home-manager.lib.homeManagerConfiguration {
        system = "x86_64-linux";
        username = "dwf";
        homeDirectory = "/home/dwf";
        stateVersion = "21.11";
        configuration = import ./home-manager/hosts/skyquake;
      };
    };
    nixosModules = {
      # Tiny module which enables tagging the system with the flake revision.
      # (visible as `configurationRevision` in nixos-version --json)
      addConfigRevision.system = {
        configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
      };

      # Module that adds a display manager session called "user-xsession" which
      # invokes ~/.xsession, which can then be managed by home-manager.
      user-xsession = import ./nixos/modules/user-xsession.nix;

      # Hardware profile for MacBookPro11,1, used by skyquake.
      macbook-pro-11-1 = {
        imports = [
          # Inherit generic Intel CPU and SSD configuration from nixos-hardware.
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          ./nixos/profiles/macbook-pro-11-1.nix
        ];
      };
    };
    nixosConfigurations = {
      skyquake = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.addConfigRevision
          self.nixosModules.macbook-pro-11-1
          self.nixosModules.user-xsession
          ./nixos/profiles/global.nix
          ./nixos/profiles/efi.nix
          ./nixos/hosts/skyquake
        ];
      };
    };
  };
}
