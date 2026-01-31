{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mineshspc = {
      url = "github:ColoradoSchoolOfMines/mineshspc.com";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      colmena,
      nixpkgs,
      flake-parts,
      ...
    }:
    {
      colmenaHive = colmena.lib.makeHive self.outputs.colmena;
      colmena = import ./nixos/colmena.nix inputs;
    }
    // (flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
          };

          formatter = pkgs.nixfmt-tree;

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              colmena.packages.${system}.colmena
              nixfmt-tree
              openssl
              pre-commit
              sops
            ];
          };
        };
    });
}
