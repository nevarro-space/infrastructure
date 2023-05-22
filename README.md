# Nevarro Infrastructure

[![Deploy Infrastructure](https://github.com/nevarro-space/infrastructure/actions/workflows/deploy.yml/badge.svg)](https://github.com/nevarro-space/infrastructure/actions/workflows/deploy.yml)

This repository contains the configuration for all servers operated by
[Nevarro LLC](https://nevarro.space).

The servers are running on Hetzner and provisioned by Terraform. The
configuration is managed by [colmena](https://colmena.cli.rs/).

## Servers

* **monitoring** - runs the monitoring stack
* **matrix** - runs the nevarro.space matrix homeserver
* **mineshspc** - runs the [mineshspc.com](https://mineshspc.com) website

## How to deploy manually

1. Run `direnv allow`.
2. Run `terraform login` to log in to Terraform Cloud.
3. Run `terraform plan` to check and see what needs to be applied.
4. Run `terraform apply` to provision all of the infrastructure.
5. Run `colmena apply` to setup all of the NixOS machines.
