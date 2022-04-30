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
      profiles.git = import ./home-manager/profiles/git.nix;
      profiles.tmux = import ./home-manager/profiles/tmux;
    };
    homeConfigurations = let
      homeManagerConfiguration =
        nixpkgs.lib.makeOverridable
        home-manager.lib.homeManagerConfiguration;
      username = "dwf";
      homeDirectory = "/home/dwf";
      stateVersion = "21.11";
      i3GraphicalDesktop = [
        ./home-manager/profiles/graphical.nix
        ./home-manager/profiles/i3.nix
      ];
    in {
      dwf = homeManagerConfiguration {
        system = "x86_64-linux";
        inherit username homeDirectory stateVersion;
        configuration.imports = [ ./home-manager/hosts ];
      };
      "dwf@shockwave" = homeManagerConfiguration {
        system = "aarch64-linux";
        inherit username homeDirectory stateVersion;
        configuration.imports = [ ./home-manager/hosts ];
      };
      "dwf@skyquake" = homeManagerConfiguration {
        system = "x86_64-linux";
        inherit username homeDirectory stateVersion;
        configuration.imports = [ ./home-manager/hosts/skyquake ];
        extraModules = i3GraphicalDesktop;
      };
      "dwf@wheeljack" = homeManagerConfiguration {
        system = "x86_64-linux";
        inherit username homeDirectory stateVersion;
        configuration.imports = [ ./home-manager/hosts ];
        extraModules = i3GraphicalDesktop;
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
      hardware.macbook-pro-11-1 = {
        imports = [
          # Inherit generic Intel CPU and SSD configuration from nixos-hardware.
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          ./nixos/profiles/macbook-pro-11-1.nix
        ];
      };

      machines = let
        mkMachine = (name: modules: {
          imports = [
            addConfigRevision
            ./nixos/profiles/global.nix
            (./. + "/nixos/hosts/${name}")
          ] ++ modules;
        });
      in nixpkgs.lib.mapAttrs mkMachine {
        bumblebee = [];
        cliffjumper = [
          ./nixos/profiles/disable-efi.nix
          "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
        ];
        shockwave = [
          ./nixos/profiles/disable-efi.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          nixos-hardware.nixosModules.common-pc-ssd
        ];
        skyquake = [
          hardware.macbook-pro-11-1
          user-xsession
          ./nixos/profiles/desktop.nix
        ];
        wheeljack = [
          user-xsession
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/remote-build.nix
        ];
      };
    };
    nixosConfigurations = let
      nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;
      defaultSystem = "x86_64-linux";
      systemOverrides = {
        shockwave = "aarch64-linux";
      };
      mkConfiguration = (name: module: nixosSystem {
        system =
          if (builtins.hasAttr name systemOverrides) then
          (builtins.getAttr name systemOverrides)
          else
          defaultSystem;
        modules = [ module ];
      });
    in nixpkgs.lib.mapAttrs mkConfiguration self.nixosModules.machines;
  };
}
