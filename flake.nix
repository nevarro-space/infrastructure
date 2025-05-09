{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mineshspc = {
      url = "github:ColoradoSchoolOfMines/mineshspc.com";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs@{ self, colmena, nixpkgs, flake-utils, ... }:
    {
      colmenaHive = colmena.lib.makeHive self.outputs.colmena;
      colmena = import ./nixos/colmena.nix inputs;
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cargo
            colmena.packages.${system}.colmena
            openssl
            pre-commit
            sops
          ];
        };
      }));
}
