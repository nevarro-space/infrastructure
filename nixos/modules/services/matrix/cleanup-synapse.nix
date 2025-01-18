# See:
# - https://levans.fr/shrink-synapse-database.html
# - https://foss-notes.blog.nomagic.uk/2021/03/matrix-database-house-cleaning/
# - https://git.envs.net/envs/matrix-conf/src/branch/master/usr/local/bin
{ config, lib, pkgs, ... }:
with pkgs;
with lib;
let
  cfg = config.services.cleanup-synapse;
  synapseCfg = config.services.matrix-synapse;

  adminV1Url = "http://localhost:8008/_synapse/admin/v1";
  adminV2Url = "http://localhost:8008/_synapse/admin/v2";
  adminMediaRepoUrl = "http://localhost:8011/_synapse/admin/v1";
  adminCurl =
    ''${curl}/bin/curl --header "Authorization: Bearer $CLEANUP_ACCESS_TOKEN"'';

  # Delete old cached remote media
  purgeRemoteMedia = writeShellScriptBin "purge-remote-media" ''
    set -xe
    before_ts=$(date +%s%3N --date='1 month ago')
    ${adminCurl} -X POST "${adminMediaRepoUrl}/purge_media_cache?before_ts=$before_ts"
  '';

  # Get rid of any rooms that aren't joined by anyone from the homeserver.
  cleanupForgottenRooms = writeShellScriptBin "cleanup-forgotten-rooms" ''
    set -xe

    total_rooms=$(${adminCurl} '${adminV1Url}/rooms?limit=1' | ${jq}/bin/jq -r '.total_rooms')
    echo "total_rooms: $total_rooms"
    total_rooms=$(( total_rooms + 10 ))

    # Find all of the rooms that have no local users.
    ${adminCurl} "${adminV1Url}/rooms?limit=$total_rooms" |
      ${jq}/bin/jq -r '.rooms[] | select(.joined_local_members == 0) | .room_id' |
      while read room_id; do
        echo "deleting $room_id..."
        ${adminCurl} \
          -X DELETE \
          -H "Content-Type: application/json" \
          -d "{}" \
          "${adminV2Url}/rooms/$room_id"
      done
  '';

  # Delete non-local room history that is older than a month in some of the
  # large rooms where I really don't care about the history.
  #
  # Best way to generate this list is:
  #
  #    > select count(*) c, room_id from events group by room_id order by c desc;
  #
  # within the matrix-synapse database.
  # roomList = concatStringsSep "\n" [
  #   "!KqkRjyTEzAGRiZFBYT:nixos.org" # #nix:nixos.org
  #   "!XPxwZVXpPnNWmrJQwB:beeper.com" # beeper commits
  #   "!wcajitOCLVswYZViyZ:beeper.com" # bc-infra-alerts
  #   "!ping-v10.1:maunium.net" # #ping:maunium.net
  #   "!aUhETchlgthwWVQzhi:matrix.org" # #gtk:gnome.org
  #   "!YTvKGNlinIzlkMTVRl:matrix.org" # #element-web:matrix.org
  #   "!NUhzqvfxHSIzJfxoVw:beeper.com" # bc-issues
  #   "!QQpfJfZvqxbCfeDgCj:matrix.org" # #thisweekinmatrix:matrix.org
  #   "!SMloEYlhCiqKwRLAgY:fachschaften.org" # #conduit:fachschaften.org
  #   "!UbCmIlGTHNIgIRZcpt:nheko.im" # #nheko:nheko.im
  #   "!KlacjKWnARbprTLuRM:nova.chat" # #beeper:beeper.com
  #   "!iupBrYlVdqKLEkWtDs:tapenet.org" # #go-lang:matrix.org
  #   "!NasysSDfxKxZBzJJoE:matrix.org" # #matrix-spec:matrix.org
  #   "!kjdutkOsheZdjqYmqp:nixos.org" # #dev:nixos.org
  # ];
  # purgeHistoryOfLargeRooms = writeShellScriptBin "purge-history" ''
  #   set -xe

  #   before_ts=$(date +%s%3N --date='1 month ago')

  #   echo '${roomList}' | while read room_id; do
  #     echo "purging history for $room_id..."
  #     ${adminCurl} -X POST -H "Content-Type: application/json" \
  #       -d "{ \"delete_local_events\": false, \"purge_up_to_ts\": $before_ts }" \
  #       "${adminV1Url}/purge_history/$room_id"
  #   done
  # '';

  compressState = writeShellScriptBin "compress-state" ''
    set -xe

    ${matrix-synapse-tools.rust-synapse-compress-state}/bin/synapse_auto_compressor \
      -p "host=localhost user=matrix-synapse password=synapse dbname=matrix-synapse" \
      -c 1000 \
      -n 200

    #echo 'Running VACUUM and ANALYZE for state_groups_state ...'
    #echo 'VACUUM FULL ANALYZE state_groups_state' |
    #  /run/wrappers/bin/sudo -u postgres ${postgresql}/bin/psql -d matrix-synapse
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
in {
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

    # systemd.services.matrix-synapse-compress-state = {
    #   description = "Compress state";
    #   startAt = "*-*-* 05:00:00";
    #   serviceConfig = {
    #     ExecStart = "${compressState}/bin/compress-state";
    #     PrivateTmp = true;
    #     Restart = "on-failure";
    #     RestartSec = "30";
    #     ProtectSystem = true;
    #     ProtectHome = "read-only";
    #   };
    # };

    # systemd.services.matrix-synapse-purge-history = {
    #   description = "Purge history of large rooms";
    #   serviceConfig = {
    #     ExecStart = "${purgeHistoryOfLargeRooms}/bin/purge-history";
    #     EnvironmentFile = cfg.environmentFile;
    #     PrivateTmp = true;
    #     Restart = "on-failure";
    #     RestartSec = "30";
    #     ProtectSystem = true;
    #     ProtectHome = "read-only";
    #   };
    # };

    # systemd.services.matrix-synapse-reindex-and-vaccum = {
    #   description = "Cleanup synapse";
    #   startAt = "*-10"; # Cleanup everything on the 10th of each month.
    #   serviceConfig = {
    #     ExecStart = "${reindexAndVaccum}/bin/reindex-and-vaccum";
    #     PrivateTmp = true;
    #     ProtectSystem = true;
    #     ProtectHome = "read-only";
    #   };
    # };

    # Allow root to manage matrix-synapse database.
    services.postgresql.ensureUsers = [{
      name = "root";
    }];
  };
}
