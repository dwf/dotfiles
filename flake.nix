{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-raspberrypi.url = "github:NixOS/nixpkgs/adc7c6f1bbaa73cda26be2323353b63a05b42f61";
    nixpkgs-jupyterhub-pinned.url = "github:NixOS/nixpkgs/3c8a5fa9a699d6910bbe70490918f1a4adc1e462";
    nixpkgs-ollama.url = "github:NixOS/nixpkgs/f173d0881eff3b21ebb29a2ef8bedbc106c86ea5";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    framework-audio-presets = {
      url = "github:ceiphr/ee-framework-presets";
      flake = false;
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agentspace = {
      url = "github:shazow/agentspace";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    # numtide's llm-agents.nix: broad collection of agent CLIs incl. claude-code.
    # Deliberately NOT following our nixpkgs, to keep its binary cache hits (its
    # outputs are keyed to its own nixpkgs). Baked into the guest so it's realized
    # once on the host and shared read-only into the VM.
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs@{
      self,
      flake-utils,
      nixpkgs,
      nixos-hardware,
      home-manager,
      ...
    }:
    {
      homeManagerModules = {
        profiles = {
          bat = import ./home-manager/profiles/bat.nix;
          eza = import ./home-manager/profiles/eza.nix;
          fzf = import ./home-manager/profiles/fzf;
          git = import ./home-manager/profiles/git.nix;
          i3 = import ./home-manager/profiles/x11/i3.nix;
          starship = import ./home-manager/profiles/starship;
          tmux = import ./home-manager/profiles/tmux;
          vivid = import ./home-manager/profiles/vivid.nix;
          zoxide = import ./home-manager/profiles/zoxide.nix;
          zsh = import ./home-manager/profiles/zsh.nix;
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        neovim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
          module = {
            nixpkgs.source = nixpkgs;
            imports = [ ./neovim/default.nix ];
          };
        };
      in
      {
        packages = {
          inherit neovim;

          # Nest homeConfigurations under packages to both be a recognized location
          # by `home-manager switch --flake` and benefit from `eachDefaultSystem`.
          homeConfigurations =
            with nixpkgs.lib;
            let
              user = "dwf";
              mkHome =
                {
                  hostname ? null,
                  username ? user,
                  stateVersion ? "21.11",
                  homePath ? "/home",
                  homeDirectory ? "${homePath}/${username}",
                  nixpkgs ? inputs.nixpkgs,
                  includeNvim ? hostname != null,
                }:
                home-manager.lib.homeManagerConfiguration {
                  pkgs = nixpkgs.legacyPackages.${system};
                  modules = [
                    (if hostname == null then ./home-manager/hosts else ./home-manager/hosts/${hostname})
                    {
                      home = {
                        inherit username homeDirectory stateVersion;
                        packages = optionals includeNvim [ neovim ];
                      };
                    }
                  ];
                  extraSpecialArgs = { inherit inputs; };
                };
            in
            listToAttrs (
              map
                (
                  hostname:
                  nameValuePair (concatStringsSep "@" ([ user ] ++ optionals (hostname != null) [ hostname ]))
                    (mkHome {
                      inherit hostname;
                    })
                )
                [
                  null
                  "shockwave"
                  "skyquake"
                  "superion"
                  "wheeljack"
                  "soundwave"
                ]
            );

          flpak = import ./pkgs/flpak.nix {
            inherit (nixpkgs) lib;
            pkgs = nixpkgs.legacyPackages.${system};
          };
        }
        // (import ./pkgs/zelda3 { pkgs = nixpkgs.legacyPackages.${system}; });

        # agentspace microVM sandbox, defined in vms/agentspace/claude/.
        # `nix run .#claude-vm` boots into Claude Code on the launch-time cwd;
        # `nix run .#claude-vm-shell` gives a debug shell in the same VM. The impure
        # per-project `claude-vm` wrapper is vms/agentspace/claude/wrappers.nix.
        apps = nixpkgs.lib.optionalAttrs (system == "x86_64-linux") (
          import ./vms/agentspace/claude/apps.nix {
            inherit inputs system;
            pkgs = nixpkgs.legacyPackages.${system};
          }
        );
      }
    )
    // rec {
      nixosModules = rec {
        # Hardware profile for MacBookPro11,1, used by skyquake.
        hardware.macbook-pro-11-1 = {
          imports = [
            # Inherit generic Intel CPU and SSD configuration from nixos-hardware.
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            ./nixos/profiles/macbook-pro-11-1.nix
          ];
        };

        # Syntactic sugar for setting up HTTPS reverse proxy gateways with
        # certificates provided by Tailscale.
        tailscale-https-reverse-proxy = import ./nixos/modules/tailscale-https.nix;

        # TigerVNC with noVNC web client frontend all managed by systemd.
        vnc = import ./nixos/modules/vnc.nix;

        machines =
          let
            jupyterhub =
              args:
              import ./nixos/profiles/jupyterhub.nix (
                args
                // {
                  pkgs = inputs.nixpkgs-jupyterhub-pinned.legacyPackages.x86_64-linux;
                }
              );
            mkMachine =
              name: modules:
              [
                { system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev; }
                ./nixos/profiles/global.nix
                (./. + "/nixos/hosts/${name}")
              ]
              ++ modules;
          in
          nixpkgs.lib.mapAttrs mkMachine {
            bumblebee = [
              tailscale-https-reverse-proxy
              vnc
            ];
            cliffjumper = [
              ./nixos/profiles/disable-efi.nix
              "${nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
            ];
            kup = [ ];
            perceptor = [ ];
            shockwave = [
              ./nixos/profiles/disable-efi.nix
              nixos-hardware.nixosModules.raspberry-pi-4
              nixos-hardware.nixosModules.common-pc-ssd
              ./nixos/modules/auto-abcde.nix
              tailscale-https-reverse-proxy
            ];
            skyquake = [
              hardware.macbook-pro-11-1
            ];
            soundwave = [
              tailscale-https-reverse-proxy
            ];
            superion = [
              nixos-hardware.nixosModules.framework-13-7040-amd
            ];
            wheeljack = [
              tailscale-https-reverse-proxy
              jupyterhub
              ./nixos/profiles/remote-build.nix
              (import ./nixos/profiles/ollama.nix {
                nixpkgs = inputs.nixpkgs-ollama;
              })
            ];
          };
      };
      nixosConfigurations =
        let
          mkConfiguration =
            name: modules:
            let
              defaultSystem = "x86_64-linux";
              systemOverrides = {
                shockwave = "aarch64-linux";
              };
            in
            nixpkgs.lib.nixosSystem {
              inherit modules;
              system =
                if (builtins.hasAttr name systemOverrides) then
                  (builtins.getAttr name systemOverrides)
                else
                  defaultSystem;
              specialArgs = { inherit nixosModules inputs; };
            };
          crossCompile = arch: {
            nixpkgs = {
              config.allowUnsupportedSystem = true;
              hostPlatform.system = arch;
              buildPlatform.system = "x86_64-linux";
            };
          };
          raspberryPiZeroW =
            name:
            inputs.nixpkgs-raspberrypi.lib.nixosSystem {
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
        in
        {
          # Build with `nix build .#nixosConfigurations.macbook-pro-11-1-installer.config.system.build.isoImage`
          macbook-pro-11-1-installer = nixpkgs.lib.nixosSystem {
            modules = installerModules ++ [ ./nixos/media/macbook-pro-11-1.nix ];
            system = "x86_64-linux";
          };
          installer-with-sshd = nixpkgs.lib.nixosSystem {
            modules = installerModules ++ [ ./nixos/media/with-sshd.nix ];
            system = "x86_64-linux";
          };
        }
        // nixpkgs.lib.mapAttrs mkConfiguration self.nixosModules.machines
        // builtins.listToAttrs (
          map (n: nixpkgs.lib.nameValuePair n (raspberryPiZeroW n)) raspberryPiZeroWHosts
        );
    };
}
