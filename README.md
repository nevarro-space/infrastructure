# Nevarro Infrastructure

[![Deploy Infrastructure](https://github.com/nevarro-space/infrastructure/actions/workflows/deploy.yml/badge.svg)](https://github.com/nevarro-space/infrastructure/actions/workflows/deploy.yml)

This repository contains the configuration for all servers operated by
[Nevarro LLC](https://nevarro.space).

The servers are running on Hetzner. The configuration is managed by
[colmena](https://colmena.cli.rs/).

## Servers

* **monitoring** - runs the monitoring stack
* **matrix** - runs the nevarro.space matrix homeserver
* **mineshspc** - runs the [mineshspc.com](https://mineshspc.com) website

## How to deploy manually

1. Run `direnv allow`.
2. Run `colmena apply` to deploy to all of the NixOS machines.
