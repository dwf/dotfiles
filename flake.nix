{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-raspberrypi.url = "github:NixOS/nixpkgs/adc7c6f1bbaa73cda26be2323353b63a05b42f61";
    nixpkgs-jupyterhub-pinned.url = "github:NixOS/nixpkgs/3c8a5fa9a699d6910bbe70490918f1a4adc1e462";
    nixpkgs-ollama.url = "github:NixOS/nixpkgs/f173d0881eff3b21ebb29a2ef8bedbc106c86ea5";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    ragenix.url = "github:yaxitech/ragenix";
    ragenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, home-manager, ... }:
  {
    homeManagerModules = {
      profiles = {
        neovim = import ./home-manager/profiles/neovim;
        git = import ./home-manager/profiles/git.nix;
        i3 = import ./home-manager/profiles/x11/i3.nix;
        tmux = import ./home-manager/profiles/tmux;
      };
      nvim-lsp = import ./home-manager/modules/nvim-lsp.nix;
      vsnip = import ./home-manager/modules/vsnip.nix;
    };
    homeConfigurations = with nixpkgs.lib; let
      user = "dwf";
      mkHome =
        { hostname ? null
        , username ? user
        , stateVersion ? "21.11"
        , homePath ? "/home"
        , homeDirectory ? "${homePath}/${username}"
        , system ? "x86_64-linux"
        , nixpkgs ? inputs.nixpkgs
      }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [
          (if hostname == null then
            ./home-manager/hosts
           else
           ./home-manager/hosts/${hostname})
          {
            home = {
              inherit username homeDirectory stateVersion;
            };
          }
        ];
      };
    in {
      "dwf@shockwave" = mkHome {
        hostname = "shockwave";
        system = "aarch64-linux";
      };
    } // (listToAttrs (map
      (hostname: nameValuePair
        (concatStringsSep "@" ([ user ] ++ optionals (hostname != null) [ hostname ]))
        (mkHome { inherit hostname; }))
    [ null "skyquake" "superion" "wheeljack" ]));

    nixosModules = rec {
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
            { system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev; }
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
          tailscaleHttpsReverseProxy
        ];
        skyquake = [
          hardware.macbook-pro-11-1
          hardware.stadiaController
          user-xsession
          ./nixos/profiles/desktop
        ];
        superion = [
          nixos-hardware.nixosModules.framework-13-7040-amd
          user-xsession
          ./nixos/profiles/desktop
        ];
        wheeljack = [
          user-xsession
          tailscaleHttpsReverseProxy
          jupyterhub
          ./nixos/profiles/desktop
          ./nixos/profiles/remote-build.nix
          (import ./nixos/profiles/ollama.nix {
            nixpkgs = inputs.nixpkgs-ollama;
          })
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
      crossCompile = arch: {
        nixpkgs.config.allowUnsupportedSystem = true;
        nixpkgs.hostPlatform.system = arch;
        nixpkgs.buildPlatform.system = "x86_64-linux";
      };
      raspberryPiZeroW = name: inputs.nixpkgs-raspberrypi.lib.nixosSystem {
        modules = [
          "${inputs.nixpkgs-raspberrypi}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix"
          (crossCompile "armv6l-linux")
          ./nixos/profiles/rpi-zero-w
          ./nixos/profiles/global.nix
          ./nixos/profiles/disable-efi.nix
          (./. + "/nixos/hosts/${name}")
        ];
        system = "armv6l-linux";
      };
      raspberryPiZeroWHosts = [ "slamdance" ];
      installerModules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
        "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
      ];
    in {
      # Build with `nix build .#nixosConfigurations.macbook-pro-11-1-installer.config.system.build.isoImage`
      macbook-pro-11-1-installer = nixpkgs.lib.nixosSystem {
        modules = installerModules ++ [ ./nixos/media/macbook-pro-11-1.nix ];
        system = "x86_64-linux";
      };
      beelink-eq12-n100-installer = nixpkgs.lib.nixosSystem {
        modules = installerModules ++ [ ./nixos/media/beelink-eq12-n100.nix ];
        system = "x86_64-linux";
      };
    }
    // nixpkgs.lib.mapAttrs mkConfiguration self.nixosModules.machines
    // builtins.listToAttrs (map (n: nixpkgs.lib.nameValuePair n (raspberryPiZeroW n)) raspberryPiZeroWHosts);
  };
}
