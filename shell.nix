{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  propagatedBuildInputs = with pkgs; [
    cargo
    colmena
    git
    git-crypt
    nodePackages.bash-language-server
    openssl
    pre-commit
    rnix-lsp

    # Terraform + Linters
    terraform
    terraform-docs
    terraform-lsp
    tflint
    tfsec
  ];
}
