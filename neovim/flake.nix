{
  description = "An experimental flake for testing nixvim configurations";

  inputs = {
    dotfiles.url = "github:dwf/dotfiles";
    nixvim.url = "github:nix-community/nixvim/nixos-23.11";
    nixvim.inputs.nixpkgs.follows = "dotfiles/nixpkgs";
  };

  outputs = { self, nixpkgs, nixvim, ... }@inputs: let
    flake-utils = inputs.dotfiles.inputs.flake-utils;
  in flake-utils.lib.eachDefaultSystem (system: {
    packages = rec {
      nvim = nixvim.legacyPackages.${system}.makeNixvim {
        # config goes here
      };
      default = nvim;
    };
  });
}
