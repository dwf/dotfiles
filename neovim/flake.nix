{
  description = "An experimental flake for testing nixvim configurations";

  inputs = {
    dotfiles.url = "github:dwf/dotfiles";
    nixvim.url = "github:nix-community/nixvim/nixos-23.11";
    nixvim.inputs.nixpkgs.follows = "dotfiles/nixpkgs";
  };

  outputs = { self, dotfiles, nixvim, ... }@inputs: let
    flake-utils = inputs.dotfiles.inputs.flake-utils;
  in flake-utils.lib.eachDefaultSystem (system: {
    packages = let
      makeNixvim = nixvim.legacyPackages.${system}.makeNixvim;
      pkgs = dotfiles.inputs.nixpkgs.legacyPackages.${system};
    in rec {
      nvim = makeNixvim (import ./default.nix { inherit pkgs; });
      default = nvim;
    };
  });
}
