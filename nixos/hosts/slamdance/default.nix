{ lib, pkgs, ... }:
{
  imports = [ ./otg.nix ];
  networking = {
    hostName = "slamdance";
    interfaces.wlan0.useDHCP = true;
    wireless = {
      enable = true;
      interfaces = [ "wlan0" ];
    };
  };

  nixpkgs.overlays = let
    noChecks = _: {
      doCheck = false;
      doInstallCheck = false;
    };
    noPyChecks = _: {
      dontUseSetuptoolsCheck = true;
      dontUsePytestCheck = true;
    };
  in [
    # Disable checks for a variety of packages which hit a qemu bug.
    (self: super:
      with lib; let
        noChecksOverride = name: (
          nameValuePair name ((getAttr name super).overrideAttrs noChecks)
        );
      in lib.listToAttrs (map noChecksOverride (with super; [
        "boehmgc"
        "elfutils"
        "ell"
        "go_1_18"
        "jemalloc"
        "libseccomp"
        "libuv"
        "mdbook"
        "nix"  # N.B. override pkgs.nix, not nix_major_minor or nixVersions.foo
        "nlohmann_json"
        "openldap"
        "ripgrep"
      ]))
    )

    (self: super: {
      # Pulled in by libical, which is pulled in by bluez.
      # By default, glSupport = true which pulls in a bunch of unnecessary
      # stuff for a headless box, including libglvnd which fails to build.
      cairo = super.cairo.override { glSupport = false; };

      # Overriding top-level llvm stuff doesn't do the trick (I think
      # because dependencies refer directly to llvmPackages_14).
      llvmPackages_14 = super.llvmPackages_14 // {
        libllvm = super.llvmPackages_14.libllvm.overrideAttrs noChecks;
      };
      rustc = super.rustc.override {
        llvmPackages = super.rustc.llvmPackages // {
          llvm = super.rustc.llvmPackages.llvm.overrideAttrs noChecks;
        };
      };

      # Python packages require a slightly different override pattern.
      python39 = super.python39.override {
        packageOverrides = python-self: python-super: {
          pytest-xdist = python-super.pytest-xdist.overrideAttrs noPyChecks;
          hypothesis = python-super.hypothesis.overrideAttrs noPyChecks;
          chardet = python-super.chardet.overrideAttrs noChecks;
          requests = python-super.requests.overrideAttrs noChecks;
        };
      };

      # ghc is unsupported on armv6l-linux.
      nix-tree = super.emptyDirectory;
    })

    # Work around https://github.com/NixOS/nixpkgs/issues/154163
    (self: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // {
        allowMissing = true;
      });
    })
  ];

  boot.enableContainers = false;
  documentation = {
    enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };
  security.polkit.enable = false;
  services.udisks2.enable = false;
  fonts.fontconfig.enable = false;
  programs.command-not-found.enable = false;

  hardware = {
    bluetooth.enable = true;
    enableRedistributableFirmware = lib.mkForce false;
    firmware = with pkgs; [
      raspberrypiWirelessFirmware
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [ wirelesstools wpa_supplicant ];
  system.stateVersion = "22.05";
}
