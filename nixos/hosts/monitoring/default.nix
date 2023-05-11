{ config, lib, terraform-outputs, ... }: with lib; {
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "monitoring";

  services.grafana.enable = true;
  services.loki.enable = true;

  services.prometheus.scrapeIPs = mapAttrsToList
    (k: v: {
      name = elemAt (splitString "_" k) 0;
      ip = v.value;
    })
    (filterAttrs
      (k: v: lib.hasInfix "_server_internal_ip" k)
      terraform-outputs);

  services.healthcheck = {
    enable = true;
    checkId = "30252d36-5283-4fb1-89c4-ad392f817e81";
    disks = [
      { path = "/"; threshold = 95; checkId = "eb00bb37-af3c-4f4e-8eab-e14cdc9ebe97"; }
    ];
  };
}
