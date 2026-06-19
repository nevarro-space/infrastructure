# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Enter dev shell (required before colmena commands)
direnv allow

# Deploy to all hosts
colmena apply

# Deploy to a single host
colmena apply --on matrix
colmena apply --on monitoring
colmena apply --on mineshspc

# Format Nix files
nix fmt
```

Pre-commit hooks run automatically on commit: trailing whitespace, end-of-file fixer, YAML check, large-file check. Run manually with `pre-commit run --all-files`.

## Architecture

NixOS infrastructure managed by [colmena](https://colmena.cli.rs/). Three hosts on Hetzner (Ashburn), all connected via an internal `nevarronet` network (10.0.1.x).

**Hosts:**
- `monitoring` (10.0.1.2) — Prometheus, Loki, Grafana, Goatcounter
- `matrix` (10.0.1.3) — Synapse homeserver with workers, Matrix bots and bridges
- `mineshspc` (10.0.1.4) — mineshspc.com website

**Layout:**
- `nixos/colmena.nix` — hive entrypoint; defines hosts and applies overlays (e.g., mineshspc package)
- `nixos/hosts/<name>/` — per-host config (hardware, deployment keys, host-specific services)
- `nixos/modules/` — shared modules imported by all hosts via `defaults`
- `nixos/pkgs/` — custom package derivations

**Key shared modules (`nixos/modules/services/`):**
- `restic.nix` — custom backup module; exposes `services.backup.backups` attrset; backs up to Backblaze B2, restores on first boot if `.restic-backup-restored` is absent
- `healthcheck.nix` — UptimeRobot heartbeat pings for uptime and disk thresholds
- `matrix/synapse.nix` — Synapse config with workers: 2 federation senders, 2 event persisters, 1 synchotron, 1 media repo; nginx routes traffic to appropriate workers
- `matrix/` — also contains meowlnir (moderation bot), maubot, msclinkbot, cleanup-synapse

## Secrets

Secrets live in a **separate private repo** (`nevarro-space/infrastructure-secrets`), encrypted with git-crypt. CI clones that repo and copies `secrets/` into this directory before deploying.

For local deploys, you need the `secrets/` directory populated manually. Secret files are referenced in `deployment.keys` blocks in host configs and deployed to `/run/keys/` at activation time via colmena's key mechanism. Services that need secrets add `"keys"` to `SupplementaryGroups`.

## CI/CD

Push to `master` → GitHub Actions runs `colmena apply` to all hosts automatically (`.github/workflows/deploy.yml`).
