# Nevarro Infrastructure

[![Deploy Infrastructure](https://github.com/nevarro-space/infrastructure/actions/workflows/deploy.yml/badge.svg)](https://github.com/nevarro-space/infrastructure/actions/workflows/deploy.yml)

This repository contains the NixOS configuration for all servers operated by
[Nevarro LLC](https://nevarro.space).

## How to deploy manually

1. Run `direnv allow`.
2. Run `terraform login` to log in to Terraform Cloud.
3. Run `terraform plan` to check and see what needs to be applied.
4. Run `terraform apply` to provision all of the infrastructure.
