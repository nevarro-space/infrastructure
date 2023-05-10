# This is similar to
# https://github.com/NixOS/nixpkgs/blob/release-19.09/nixos/modules/services/backup/restic.nix
# But this module is a bit more specific to my use case. This is what it does:
# 1. It exposes a very simple interface to the other modules where they can
#    just specify a directory that needs to be backed up.
# 2. Each folder that's backed up by this service is backed up to B2.
# 3. After each backup, I check it's validity.
# 4. I forget old snapshots and prune every day.
# 5. It creates a new service for each of the configured backup paths that is
#    run at startup. If a special `.restic-backup-restored` file does not exist
#    in that directory, it will restore all data from B2 to that directory.
#    This service can be set as a prerequisite for starting up other services
#    that depend on that data.

{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.backup;
  bucket = "nevarro-backups";
  repoPath = config.networking.hostName;
  frequency = "0/6:0"; # Run backup every six hours
  pruneFrequency = "Sun *-*-* 02:00"; # Run prune every Sunday at 02:00
  resticEnvironmentFile = "/run/keys/restic_environment_file";
  resticRepository = "b2:${bucket}:${repoPath}";
  # TODO be able to restore from a different repo path

  resticCmd = "${pkgs.restic}/bin/restic --verbose=3";

  resticEnvironment = {
    RESTIC_PASSWORD_FILE = "/run/keys/restic_password_file";
    RESTIC_REPOSITORY = resticRepository;
    RESTIC_CACHE_DIR = "/var/cache";
  };

  # Scripts
  # ===========================================================================
  resticBackupScript = paths: exclude: pkgs.writeScriptBin "restic-backup" ''
    #!${pkgs.stdenv.shell}
    set -xe

    ${pkgs.curl}/bin/curl -fsS --retry 10 https://hc-ping.com/${cfg.healthcheckId}/start

    # Perfrom the backup
    ${resticCmd} backup \
      ${concatStringsSep " " paths} \
      ${concatMapStringsSep " " (e: "-e \"${e}\"") exclude}

    # Ping healthcheck.io
    ${pkgs.curl}/bin/curl -fsS --retry 10 https://hc-ping.com/${cfg.healthcheckId}
  '';

  resticPruneScript = pkgs.writeScriptBin "restic-prune" ''
    #!${pkgs.stdenv.shell}
    set -xe

    ${pkgs.curl}/bin/curl -fsS --retry 10 https://hc-ping.com/${cfg.healthcheckPruneId}/start

    # Check the validity of the repository.
    ${resticCmd} check

    # Remove old backup sets. Keep hourly backups from the past week, daily
    # backups for the past 90 days, weekly backups for the last half year,
    # monthly backups for the last two years, and yearly backups for the last
    # two decades.
    ${resticCmd} forget \
      --prune \
      --group-by host \
      --keep-hourly 168 \
      --keep-daily 90 \
      --keep-weekly 26 \
      --keep-monthly 24 \
      --keep-yearly 20

    # Ping healthcheck.io
    ${pkgs.curl}/bin/curl -fsS --retry 10 https://hc-ping.com/${cfg.healthcheckPruneId}
  '';

  # Services
  # ===========================================================================
  resticBackupService = backups: exclude:
    let
      paths = mapAttrsToList (n: { path, ... }: path) backups;
      script = resticBackupScript paths (exclude ++ [ ".restic-backup-restored" ]);
    in
    {
      description = "Backup ${concatStringsSep ", " paths} to ${resticRepository}";
      environment = resticEnvironment;
      startAt = frequency;
      serviceConfig = {
        ExecStart = "${script}/bin/restic-backup";
        EnvironmentFile = resticEnvironmentFile;
        PrivateTmp = true;
        ProtectSystem = true;
        ProtectHome = "read-only";
        SupplementaryGroups = [ "keys" ];
      };
      # Initialize the repository if it doesn't exist already.
      preStart = ''
        ${resticCmd} snapshots || ${resticCmd} init
      '';
    };

  resticPruneService = {
    description = "Prune ${resticRepository}";
    environment = resticEnvironment;
    startAt = pruneFrequency;
    serviceConfig = {
      ExecStart = "${resticPruneScript}/bin/restic-prune";
      EnvironmentFile = resticEnvironmentFile;
      PrivateTmp = true;
      ProtectSystem = true;
      ProtectHome = "read-only";
      SupplementaryGroups = [ "keys" ];
    };
    # Initialize the repository if it doesn't exist already.
    preStart = ''
      ${resticCmd} snapshots || ${resticCmd} init
    '';
  };
in
{
  options =
    let
      backupDirOpts = { name, ... }: {
        options = {
          path = mkOption {
            type = types.str;
            description = "The path to backup using restic.";
          };
        };
      };
    in
    {
      services.backup = {
        backups = mkOption {
          type = with types; attrsOf (submodule backupDirOpts);
          description = "List of backup configurations.";
          default = { };
        };

        exclude = mkOption {
          type = with types; listOf str;
          description = ''
            List of patterns to exclude. `.restic-backup-restored` files are
            already ignored.
          '';
          default = [ ];
          example = [ ".git/*" ];
        };

        healthcheckId = mkOption {
          type = types.str;
          description = "Healthcheck ID for this server's backup job.";
        };

        healthcheckPruneId = mkOption {
          type = types.str;
          description = "Healthcheck ID for this server's prune job.";
        };
      };
    };

  config = mkIf (cfg.backups != { }) {
    systemd.services = {
      restic-backup = resticBackupService cfg.backups cfg.exclude;
      restic-prune = resticPruneService;
    };
  };
}
