resource "hcloud_server" "monitoring" {
  name        = "monitoring"
  image       = "ubuntu-22.04"
  server_type = "cpx11"
  location    = "ash"

  ssh_keys = [
    hcloud_ssh_key.tatooine_ssh_key.id,
    hcloud_ssh_key.coruscant_ssh_key.id,
    hcloud_ssh_key.scarif_ssh_key.id,
  ]

  firewall_ids = [
    hcloud_firewall.web_server_firewall.id,
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }

  user_data = file("./cloud-init/nixos")
}

resource "hcloud_server_network" "monitoring_nevarronet" {
  server_id  = hcloud_server.monitoring.id
  network_id = hcloud_network.nevarro_network.id
  ip         = "10.0.1.2"
}

resource "hetznerdns_zone" "nevarro_space" {
  name = "nevarro.space"
  ttl  = 60
}

resource "hetznerdns_record" "nevarro_space_cname_status" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "status"
  value   = "stats.uptimerobot.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "nevarro_space_a_monitoring" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "monitoring"
  value   = hcloud_server.monitoring.ipv4_address
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_grafana" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "grafana"
  value   = hcloud_server.monitoring.ipv4_address
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_ns_1" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "helium.ns.hetzner.de."
  type    = "NS"
}

resource "hetznerdns_record" "nevarro_space_ns_2" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "hydrogen.ns.hetzner.com."
  type    = "NS"
}

resource "hetznerdns_record" "nevarro_space_ns_3" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "oxygen.ns.hetzner.com."
  type    = "NS"
}

resource "hetznerdns_record" "nevarro_space_mx_1" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "10 aspmx1.migadu.com."
  type    = "MX"
}

resource "hetznerdns_record" "nevarro_space_mx_2" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "20 aspmx2.migadu.com."
  type    = "MX"
}

resource "hetznerdns_record" "nevarro_space_a_root_1" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "185.199.108.153"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_root_2" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "185.199.109.153"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_root_3" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "185.199.110.153"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_root_4" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "185.199.111.153"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_aaaa_root_1" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "2606:50c0:8000::153"
  type    = "AAAA"
}

resource "hetznerdns_record" "nevarro_space_aaaa_root_2" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "2606:50c0:8001::153"
  type    = "AAAA"
}

resource "hetznerdns_record" "nevarro_space_aaaa_root_3" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "2606:50c0:8002::153"
  type    = "AAAA"
}

resource "hetznerdns_record" "nevarro_space_aaaa_root_4" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "2606:50c0:8003::153"
  type    = "AAAA"
}

resource "hetznerdns_record" "nevarro_space_a_grafana_kessel" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "grafana.kessel"
  value   = "5.161.43.147"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_grafana_nevarro" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "grafana.nevarro"
  value   = "45.33.24.161"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_kessel" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "kessel"
  value   = "5.161.43.147"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_matrix" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "matrix"
  value   = "5.161.43.147"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_nevarro" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "nevarro"
  value   = "45.33.24.161"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_turn" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "turn"
  value   = "5.161.43.147"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_voip" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "voip"
  value   = "5.161.43.204"
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_cname_autoconfig" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "autoconfig"
  value   = "autoconfig.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "nevarro_space_srv_autodiscover_tcp" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "_autodiscover._tcp"
  value   = "0 1 443 autodiscover.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "nevarro_space_srv_imaps_tcp" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "_imaps._tcp"
  value   = "0 1 993 imap.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "nevarro_space_srv_pop3s_tcp" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "_pop3s._tcp"
  value   = "0 1 995 pop.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "nevarro_space_srv_submissions_tcp" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "_submissions._tcp"
  value   = "0 1 465 smtp.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "nevarro_space_cname_domainkey_1" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "key1._domainkey"
  value   = "key1.nevarro.space._domainkey.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "nevarro_space_cname_domainkey_2" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "key2._domainkey"
  value   = "key2.nevarro.space._domainkey.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "nevarro_space_cname_domainkey_3" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "key3._domainkey"
  value   = "key3.nevarro.space._domainkey.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "nevarro_space_spf" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "\"v=spf1 include:spf.migadu.com -all\""
  type    = "TXT"
}

resource "hetznerdns_record" "nevarro_space_hosted_email_verify" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "@"
  value   = "hosted-email-verify=olu4dcza"
  type    = "TXT"
}

resource "hetznerdns_record" "nevarro_space_dmarc" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "_dmarc"
  value   = "\"v=DMARC1; p=reject;\""
  type    = "TXT"
}

resource "hetznerdns_record" "nevarro_space_github_challenge_nevarro_space_org" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "_github-challenge-nevarro-space-org"
  value   = "eedc1c983a"
  type    = "TXT"
}
