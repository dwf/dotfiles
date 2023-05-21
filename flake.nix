{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-raspberrypi.url = "github:NixOS/nixpkgs/nixos-22.11";
    nixpkgs-jupyterhub-pinned.url = "github:NixOS/nixpkgs/3c8a5fa9a699d6910bbe70490918f1a4adc1e462";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, ... }: {
    homeManagerModules = {
      profiles.neovim = import ./home-manager/profiles/neovim;
      profiles.git = import ./home-manager/profiles/git.nix;
      profiles.i3 = import ./home-manager/profiles/i3.nix;
      profiles.tmux = import ./home-manager/profiles/tmux;
      nvim-lsp = import ./home-manager/modules/nvim-lsp.nix {
        lua = ./home-manager/lib/lua.nix;
      };
      vsnip = import ./home-manager/modules/vsnip.nix;
    };
    homeConfigurations = let
      hmConfig = { system ? "x86_64-linux", modules }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = modules ++ [
            {
              home = {
                username = "dwf";
                homeDirectory = "/home/dwf";
                stateVersion = "21.11";
              };
            }
          ];
        }
      ;
      i3GraphicalDesktop = [
        ./home-manager/profiles/decorations.nix
        ./home-manager/profiles/graphical.nix
        ./home-manager/profiles/i3.nix
        ./home-manager/profiles/rofi.nix
      ];
    in {
      dwf = hmConfig {
        modules = [ ./home-manager/hosts ];
      };
      "dwf@shockwave" = hmConfig {
        system = "aarch64-linux";
        modules = [ ./home-manager/hosts ];
      };
      "dwf@skyquake" = hmConfig {
        modules = i3GraphicalDesktop ++ [
          ./home-manager/hosts/skyquake
        ];
      };
      "dwf@wheeljack" = hmConfig {
        modules = i3GraphicalDesktop ++ [
          ./home-manager/hosts/wheeljack
        ];
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

      hardware.stadiaController = import ./nixos/modules/stadia-controller.nix;

      # Syntactic sugar for setting up HTTPS reverse proxy gateways with
      # certificates provided by Tailscale.
      tailscaleHttpsReverseProxy = import ./nixos/modules/tailscale-https.nix;

      # TigerVNC with noVNC web client frontend all managed by systemd.
      vnc = import ./nixos/modules/vnc.nix;

      machines = let
        jupyterhub = args@{ ... }: import ./nixos/profiles/jupyterhub.nix (args // {
          pkgs = inputs.nixpkgs-jupyterhub-pinned.legacyPackages.x86_64-linux;
        });
        mkMachine = (name: modules: [
            addConfigRevision
            ./nixos/profiles/global.nix
            (./. + "/nixos/hosts/${name}")
          ] ++ modules);
      in nixpkgs.lib.mapAttrs mkMachine {
        bumblebee = [
          tailscaleHttpsReverseProxy
          vnc
        ];
        cliffjumper = [
          ./nixos/profiles/disable-efi.nix
          "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
        ];
        shockwave = [
          ./nixos/profiles/disable-efi.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          nixos-hardware.nixosModules.common-pc-ssd
          ./nixos/modules/auto-abcde.nix
        ];
        skyquake = [
          hardware.macbook-pro-11-1
          hardware.stadiaController
          user-xsession
          ./nixos/profiles/desktop.nix
        ];
        wheeljack = [
          user-xsession
          tailscaleHttpsReverseProxy
          jupyterhub
          ./nixos/profiles/desktop.nix
          ./nixos/profiles/remote-build.nix
        ];
      };
    };
    nixosConfigurations = let
      mkConfiguration = (name: modules:
        let
          defaultSystem = "x86_64-linux";
          systemOverrides = {
            shockwave = "aarch64-linux";
          };
        in nixpkgs.lib.nixosSystem {
          inherit modules;
          system =
            if (builtins.hasAttr name systemOverrides) then
            (builtins.getAttr name systemOverrides)
            else defaultSystem;
        });
    in {
      slamdance = inputs.nixpkgs-raspberrypi.lib.nixosSystem {
        modules = [
          "${inputs.nixpkgs-raspberrypi}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix"
          ./nixos/profiles/rpi-zero-w
          ./nixos/profiles/global.nix
          ./nixos/profiles/disable-efi.nix
          ./nixos/hosts/slamdance
          {
            nixpkgs.config.allowUnsupportedSystem = true;
            nixpkgs.hostPlatform.system = "armv6l-linux";
            nixpkgs.buildPlatform.system = "x86_64-linux";
          }
        ];
        system = "armv6l-linux";
      };
      # Build with `nix build .#nixosConfigurations.macbook-pro-11-1-installer.config.system.build.isoImage`
      macbook-pro-11-1-installer = nixpkgs.lib.nixosSystem {
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./nixos/media/macbook-pro-11-1.nix
        ];
        system = "x86_64-linux";
      };
    } // nixpkgs.lib.mapAttrs mkConfiguration self.nixosModules.machines;
  };
}
