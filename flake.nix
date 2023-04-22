{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs: {
    colmena = import ./nixos/colmena.nix inputs;
  };
}
