{ config, lib, pkgs, ... }: with lib; let
  cfg = config.services.matrix-chessbot;
  matrix-chessbot = pkgs.callPackage ../../../pkgs/matrix-chessbot.nix { };

  matrixChessbotConfig = {
    username = cfg.username;
    homeserver = cfg.homeserver;
    password_file = cfg.passwordFile;
  };
  format = pkgs.formats.yaml { };
  configYaml = format.generate "matrix-chessbot.config.yaml" matrixChessbotConfig;
in
{
  options = {
    services.matrix-chessbot = {
      enable = mkEnableOption "matrix-chessbot";
      username = mkOption { type = types.str; };
      homeserver = mkOption { type = types.str; };
      passwordFile = mkOption { type = types.path; };
      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/matrix-chessbot";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.matrix-chessbot = {
      description = "Matrix Chessbot";
      after = [
        "matrix-synapse.target"
        "chessbot_password-key.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.imagemagick ];
      serviceConfig = {
        ExecStart = ''
          ${matrix-chessbot}/bin/matrix-chessbot \
            --config ${configYaml} \
            --dbfile ${cfg.dataDir}/chessbot.db
        '';
        Restart = "on-failure";
        User = "matrix-chessbot";
        Group = "matrix-chessbot";
        SupplementaryGroups = [ "keys" ];
      };
    };

    users = {
      users.matrix-chessbot = {
        group = "matrix-chessbot";
        isSystemUser = true;
        home = cfg.dataDir;
        createHome = true;
      };
      groups.matrix-chessbot = { };
    };

    # Add a backup service.
    services.backup.backups.matrix-chessbot = {
      path = cfg.dataDir;
    };
  };
}
