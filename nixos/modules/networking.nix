{
  networking.domain = "nevarro.space";

  systemd.network = {
    enable = true;
    networks = {
      "10-wan".networkConfig.DHCP = "ipv4";
      "10-nevarronet".networkConfig.DHCP = "ipv4";
    };
  };

  services.fail2ban.enable = true;
}
