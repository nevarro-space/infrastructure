{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ nixpkgs-unstable, ... }: {
    colmena = import ./nixos/colmena.nix (inputs // {
      terraform-outputs = nixpkgs-unstable.lib.importJSON ./terraform-output.json;
    });
  };
}
