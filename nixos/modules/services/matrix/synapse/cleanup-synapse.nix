# See:
# - https://levans.fr/shrink-synapse-database.html
# - https://foss-notes.blog.nomagic.uk/2021/03/matrix-database-house-cleaning/
# - https://git.envs.net/envs/matrix-conf/src/branch/master/usr/local/bin
{ config, lib, pkgs, ... }:
with pkgs;
with lib;
let
  cfg = config.services.cleanup-synapse;
  synapseCfg = config.services.matrix-synapse-custom;

  adminUrl = "http://localhost:8008/_synapse/admin/v1";
  adminMediaRepoUrl = "http://localhost:8011/_synapse/admin/v1";
  adminCurl = ''${curl}/bin/curl --header "Authorization: Bearer $CLEANUP_ACCESS_TOKEN"'';

  # Delete old cached remote media
  purgeRemoteMedia = writeShellScriptBin "purge-remote-media" ''
    set -xe

    prune_before_ts=$(date +%s%3N --date='1 month ago')

    ${adminCurl} \
      -X POST \
      -H "Content-Type: application/json" \
      -d "{}" \
      "${adminMediaRepoUrl}/purge_media_cache?before_ts=$prune_before_ts"
  '';

  # Get rid of any rooms that aren't joined by anyone from the homeserver.
  cleanupForgottenRooms = writeShellScriptBin "cleanup-forgotten-rooms" ''
    set -xe

    roomlist=$(mktemp)
    to_purge=$(mktemp)

    ${adminCurl} '${adminUrl}/rooms?limit=1000' > $roomlist

    # Find all of the rooms that have no local users.
    ${jq}/bin/jq -r '.rooms[] | select(.joined_local_members == 0) | .room_id' < $roomlist > $to_purge

    while read room_id; do
      echo "deleting $room_id..."
      ${adminCurl} \
        -X DELETE \
        -H "Content-Type: application/json" \
        -d "{}" \
        "${adminUrl}/rooms/$room_id"
    done < $to_purge
  '';

  # TODO do this for only a defined set of rooms
  # # Delete all non-local room history that is from before 90 days ago.
  # cleanupHistory = writeShellScriptBin "cleanup-history" ''
  #   set -xe
  #   roomlist=$(mktemp)

  #   ${adminCurl} '${adminUrl}/rooms?limit=1000' |
  #     ${jq}/bin/jq -r '.rooms[] | .room_id' > $roomlist

  #   now=$(${coreutils}/bin/date +%s%N | ${coreutils}/bin/cut -b1-13)
  #   nintey_days_ago=$(( now - 7776000000 ))

  #   while read room_id; do
  #     echo "purging history for $room_id..."

  #     ${adminCurl} -X POST -H "Content-Type: application/json" \
  #       -d "{ \"delete_local_events\": false, \"purge_up_to_ts\": $nintey_days_ago }" \
  #       "${adminUrl}/purge_history/$room_id"
  #   done < $roomlist
  # '';

  compressState = writeShellScriptBin "compress-state" ''
    set -xe

    ${matrix-synapse-tools.rust-synapse-compress-state}/bin/synapse_auto_compressor \
      -p "host=localhost user=matrix-synapse password=synapse dbname=matrix-synapse" \
      -c 500 \
      -n 100

    echo 'Running VACUUM and ANALYZE for state_groups_state ...'
    echo 'VACUUM FULL ANALYZE state_groups_state' |
      /run/wrappers/bin/sudo -u postgres ${postgresql}/bin/psql -d matrix-synapse
  '';

  reindexAndVaccum = writeShellScriptBin "reindex-and-vaccum" ''
    set -xe
    systemctl stop matrix-synapse.target

    echo 'REINDEX (VERBOSE) DATABASE "matrix-synapse"' |
      /run/wrappers/bin/sudo -u postgres ${postgresql}/bin/psql -d matrix-synapse

    echo "VACUUM FULL VERBOSE" |
      /run/wrappers/bin/sudo -u postgres ${postgresql}/bin/psql -d matrix-synapse

    systemctl start matrix-synapse.target
  '';
in
{
  options.services.cleanup-synapse = {
    environmentFile = mkOption {
      type = types.path;
      description = "The environment file for the synapse cleanup script.";
    };
  };

  config = mkIf synapseCfg.enable {
    systemd.services.matrix-synapse-purge-remote-media = {
      description = "Purge remote media in Synapse";
      startAt = "*-*-* 02:00:00";
      serviceConfig = {
        ExecStart = "${purgeRemoteMedia}/bin/purge-remote-media";
        EnvironmentFile = cfg.environmentFile;
        PrivateTmp = true;
        ProtectSystem = true;
        ProtectHome = "read-only";
      };
    };

    systemd.services.matrix-synapse-cleanup-forgotten-rooms = {
      description = "Cleanup forgotten rooms in Synapse";
      startAt = "*-*-* 02:00:00";
      serviceConfig = {
        ExecStart = "${cleanupForgottenRooms}/bin/cleanup-forgotten-rooms";
        EnvironmentFile = cfg.environmentFile;
        PrivateTmp = true;
        ProtectSystem = true;
        ProtectHome = "read-only";
      };
    };

    systemd.services.matrix-synapse-compress-state = {
      description = "Compress state";
      startAt = "*-*-* 05:00:00";
      serviceConfig = {
        ExecStart = "${compressState}/bin/compress-state";
        PrivateTmp = true;
        Restart = "on-failure";
        RestartSec = "30";
        ProtectSystem = true;
        ProtectHome = "read-only";
      };
    };

    # systemd.services.matrix-synapse-reindex-and-vaccum = {
    #   description = "Cleanup synapse";
    #   startAt = "*-10"; # Cleanup everything on the 10th of each month.
    #   serviceConfig = {
    #     ExecStart = "${reindexAndVaccum}/bin/reindex-and-vaccum";
    #     EnvironmentFile = cfg.environmentFile;
    #     PrivateTmp = true;
    #     ProtectSystem = true;
    #     ProtectHome = "read-only";
    #   };
    # };

    # Allow root to manage matrix-synapse database.
    services.postgresql.ensureUsers = [
      {
        name = "root";
        ensurePermissions = {
          "DATABASE \"matrix-synapse\"" = "ALL PRIVILEGES";
          "ALL TABLES IN SCHEMA public" = "ALL PRIVILEGES";
        };
      }
    ];
  };
}
