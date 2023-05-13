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
      mscbot_password = keyFor "matrix/bots/mscbot" "msclinkbot";
      chessbot_password = keyFor "matrix/bots/chessbot" "matrix-chessbot";
      # nevarro_space_registration_shared_secret = keyFor "matrix/registration-shared-secret/nevarro.space" "matrix-synapse";
      # nevarro_space_shared_secret_auth = keyFor "matrix/shared-secret-auth/nevarro.space" "matrix-synapse";
      nevarro_space_cleanup_synapse_environment_file = keyFor "matrix/cleanup-synapse/nevarro.space" "root";
    };

  networking.hostName = "matrix2";

  services.healthcheck = {
    enable = true;
    checkId = "d7eae3e9-de4c-452b-9142-60e7831874c3";
    disks = [
      { path = "/"; threshold = 95; checkId = "5406129d-1352-4a24-b2db-6daa0c0a3d8f"; }
      { path = "/mnt/postgresql-data"; threshold = 95; checkId = "2b04d70f-f432-4359-aab3-f0d2ba6d8995"; }
    ];
  };

  services.backup = {
    healthcheckId = "e3b7948f-42cd-4571-a400-f77401d7dc56";
    healthcheckPruneId = "197d3821-bbf0-4081-b388-8d9dc1c2f11f";
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

  # Synapse
  # services.matrix-synapse-custom = {
  #   enable = true;
  #   registrationSharedSecretConfigFile = "/run/keys/nevarro_space_registration_shared_secret";
  #   sharedSecretAuthConfigFile = "/run/keys/nevarro_space_shared_secret_auth";
  # };
  # services.cleanup-synapse.environmentFile = "/run/keys/nevarro_space_cleanup_synapse_environment_file";
}
