{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  propagatedBuildInputs = with pkgs; [
    git-crypt
    # nixops_unstable
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
