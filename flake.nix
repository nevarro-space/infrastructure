{
  description = "Nevarro Infrastructure NixOS deployments";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mineshspc = {
      url = "github:ColoradoSchoolOfMines/mineshspc.com";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    meetbot = {
      url = "github:beeper/meetbot";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs@{ nixpkgs, flake-utils, ... }:
    {
      colmena = import ./nixos/colmena.nix (inputs // {
        terraform-outputs = nixpkgs.lib.importJSON ./terraform-output.json;
      });
    } // (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
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
