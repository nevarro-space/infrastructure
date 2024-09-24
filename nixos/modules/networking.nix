{
  networking.domain = "nevarro.space";

  systemd.network = {
    enable = true;
    networks = {
      "10-wan" = {
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
        routes = [{ Gateway = "fe80::1"; }];
      };
      "10-nevarronet" = {
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
        };
      };
    };
  };

  services.fail2ban.enable = true;
}
