{ config, lib, pkgs, ... }:
with lib;
let
  healthcheckCfg = config.services.healthcheck;

  curlCmd = concatStringsSep " " [
    "${pkgs.curl}/bin/curl"
    "--verbose"
    "-fsS"
    "--retry 3"
    "--max-time 5"
    "--ipv4"
  ];

  # https://blog.healthchecks.io/2023/05/monitor-disk-space-on-servers-without-installing-monitoring-agents/
  diskCheckScript = with pkgs;
    { path, threshold, url }:
    writeShellScriptBin "diskcheck" ''
      set -xe
      pct=$(${coreutils}/bin/df --output=pcent ${path} | ${coreutils}/bin/tail -n 1 | ${coreutils}/bin/tr -d '% ')

      if [ "$pct" -gt "${toString threshold}" ] ; then
        echo "Used space on ${path} is $pct% which is over ${
          toString threshold
        }%"
      else
        ${curlCmd} ${url}
      fi
    '';

  diskCheckService = cfg@{ path, ... }: {
    name = "healthcheck-${builtins.replaceStrings [ "/" ] [ "-" ] path}";
    value = {
      description = "Healthcheck for ${path}";
      startAt = "*-*-* *:00/5:00"; # Check the disk every five minutes.
      serviceConfig = {
        ExecStart = "${diskCheckScript cfg}/bin/diskcheck";
        TimeoutSec = 10;
      };
    };
  };
in {
  options.services.healthcheck = {
    enable = mkEnableOption "pinging an endpoint veery 30 seconds";
    url = mkOption {
      type = with types; nullOr str;
      default = null;
      description = "The URL to GET.";
    };
    disks = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            path = mkOption {
              type = path;
              description = "The path where the disk is mounted.";
            };
            threshold = mkOption {
              type = int;
              default = 90;
              description = "The threshold percentage for alerting.";
            };
            url = mkOption {
              type = str;
              description = "The URL to ping when the threshold is exceeded.";
            };
          };
        });
      default = [ ];
      description = "List of disks to check with thresholds";
    };
  };

  config = mkIf healthcheckCfg.enable {
    systemd.services = mkMerge [
      (mkIf (healthcheckCfg.url != null) {
        healthcheck = {
          description = "Healthcheck server up service";
          startAt =
            "*-*-* *:*:00/30"; # Send a healthcheck ping every 30 seconds.
          serviceConfig = {
            ExecStart = "${curlCmd} ${healthcheckCfg.url}";
            TimeoutSec = 10;
          };
        };
      })
      (listToAttrs (map diskCheckService healthcheckCfg.disks))
    ];
  };
}
