{ config, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "monitoring";

  services.grafana.enable = true;
  services.loki.enable = true;

  services.healthcheck = {
    enable = true;
    checkId = "30252d36-5283-4fb1-89c4-ad392f817e81";
    disks = [ "/" ];
  };
}
