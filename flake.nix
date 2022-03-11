{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager }: {
    homeManagerModules = {
      profiles.neovim = import ./home-manager/profiles/neovim;
    };
    homeConfigurations = let
      homeManagerConfiguration =
        nixpkgs.lib.makeOverridable
        home-manager.lib.homeManagerConfiguration;
      username = "dwf";
      homeDirectory = "/home/dwf";
      stateVersion = "21.11";
    in {
      "dwf@skyquake" = homeManagerConfiguration {
        system = "x86_64-linux";
        inherit username homeDirectory stateVersion;
        configuration.imports = [ ./home-manager/hosts/skyquake ];
      };
      "dwf@shockwave" = homeManagerConfiguration {
        system = "aarch64-linux";
        inherit username homeDirectory stateVersion;
        configuration.imports = [ ./home-manager/hosts/shockwave ];
      };
    };
    nixosModules = rec {
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

      machines = {
        shockwave.imports = [
          addConfigRevision
          nixos-hardware.nixosModules.raspberry-pi-4
          nixos-hardware.nixosModules.common-pc-ssd
          ./nixos/profiles/global.nix
          ./nixos/hosts/shockwave
        ];
        skyquake.imports = [
          addConfigRevision
          macbook-pro-11-1
          user-xsession
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/efi.nix
          ./nixos/profiles/global.nix
          ./nixos/hosts/skyquake
        ];
      };
    };
    nixosConfigurations = let
      nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;
    in {
      shockwave = nixosSystem {
        system = "aarch64-linux";
        modules = [ self.nixosModules.machines.shockwave ];
      };
      skyquake = nixosSystem {
        system = "x86_64-linux";
        modules = [ self.nixosModules.machines.skyquake ];
      };
    };
  };
}
