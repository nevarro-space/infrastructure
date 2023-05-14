{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  deployment.keys =
    let
      keyFor = keyname: for: {
        keyCommand = [ "cat" "../infrastructure-secrets/secrets/${keyname}" ];
        user = for;
        group = for;
      };
    in
    {
      restic_password_file = keyFor "restic_password_file" "root";
      restic_environment_file = keyFor "restic_environment_file" "root";

      mscbot_password = keyFor "matrix/bots/mscbot" "msclinkbot";
      chessbot_password = keyFor "matrix/bots/chessbot" "matrix-chessbot";
      standupbot_password = keyFor "matrix/bots/standupbot" "standupbot";
      marshal_password = keyFor "matrix/bots/marshal" "mjolnir";
      nevarro_space_registration_shared_secret = keyFor "matrix/registration-shared-secret/nevarro.space" "matrix-synapse";
      nevarro_space_shared_secret_auth = keyFor "matrix/shared-secret-auth/nevarro.space" "matrix-synapse";
      nevarro_space_cleanup_synapse_environment_file = keyFor "matrix/cleanup-synapse/nevarro.space" "root";
      github_maubot_secrets_yaml = keyFor "matrix/bots/github.yaml" "maubot-github";
    };

  networking.hostName = "matrix";

  services.healthcheck = {
    enable = true;
    checkId = "d7eae3e9-de4c-452b-9142-60e7831874c3";
    disks = [
      { path = "/"; threshold = 95; checkId = "5406129d-1352-4a24-b2db-6daa0c0a3d8f"; }
      { path = "/mnt/postgresql-data"; threshold = 95; checkId = "2b04d70f-f432-4359-aab3-f0d2ba6d8995"; }
    ];
  };

  services.backup = {
    healthcheckId = "a60db84a-ace2-411f-89b7-961982823c60";
    healthcheckPruneId = "3d6709f9-0d86-44fc-805f-e1ad496e7006";
  };

  # Chessbot
  services.matrix-chessbot = {
    enable = true;
    username = "@chessbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/chessbot_password";
  };

  # MSC Link Bot
  services.msclinkbot = {
    enable = true;
    username = "@mscbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/mscbot_password";
  };

  # Standupbot
  services.standupbot = {
    enable = true;
    username = "@standupbot:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    passwordFile = "/run/keys/standupbot_password";
  };

  # Mjolnir
  services.mjolnir = {
    enable = true;
    homeserverUrl = "https://matrix.nevarro.space";
    managementRoom = "#mjolnir:nevarro.space";

    pantalaimon = {
      username = "marshal";
      passwordFile = "/run/keys/marshal_password";
    };
  };

  # GitHub Maubot
  services.maubot-github = {
    enable = true;
    username = "@github:nevarro.space";
    homeserver = "https://matrix.nevarro.space";
    publicUrl = "https://matrix.nevarro.space";
    secretYAML = "/run/keys/github_maubot_secrets_yaml";
  };

  # Synapse
  services.matrix-synapse-custom = {
    enable = true;
    registrationSharedSecretConfigFile = "/run/keys/nevarro_space_registration_shared_secret";
    sharedSecretAuthConfigFile = "/run/keys/nevarro_space_shared_secret_auth";
  };
  services.cleanup-synapse.environmentFile = "/run/keys/nevarro_space_cleanup_synapse_environment_file";

  # PosgreSQL
  services.postgresql.enable = true;
  services.postgresql.dataDir = "/mnt/postgresql-data/${config.services.postgresql.package.psqlSchema}";
  services.postgresqlBackup.enable = true;
}
