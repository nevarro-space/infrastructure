{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    colmena.url = "github:nix-community/colmena";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    mineshspc = {
      url = "github:ColoradoSchoolOfMines/mineshspc.com";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://colmena.cachix.org"
    ];
    extra-trusted-public-keys = [
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
    ];
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
              colmena.packages.${system}.colmena
              pre-commit
            ];
          };
        };
    });
}
