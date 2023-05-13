{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ nixpkgs-unstable, flake-utils, ... }:
    {
      colmena = import ./nixos/colmena.nix (inputs // {
        terraform-outputs = nixpkgs-unstable.lib.importJSON ./terraform-output.json;
      });
    } // (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs-unstable { system = system; };
        in
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              colmena
              git-crypt
              nodePackages.bash-language-server
              openssl
              pre-commit
              rnix-lsp
              sops

              # Terraform + Linters
              terraform
              terraform-docs
              terraform-lsp
              tflint
              tfsec
            ];
          };
        }
      ));
}
