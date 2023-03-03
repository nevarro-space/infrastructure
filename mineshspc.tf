resource "hcloud_server" "mineshspc" {
  name        = "mineshspc"
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

resource "hcloud_server_network" "mineshspc_nevarronet" {
  server_id  = hcloud_server.mineshspc.id
  network_id = hcloud_network.nevarro_network.id
  ip         = "10.0.1.1"
}

resource "hetznerdns_zone" "mineshspc_com" {
  name = "mineshspc.com"
  ttl  = 3600
}

resource "hetznerdns_record" "mineshspc_cname_status" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "status"
  value   = "stats.uptimerobot.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_ns_1" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "helium.ns.hetzner.de."
  type    = "NS"
}

resource "hetznerdns_record" "mineshspc_ns_2" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "hydrogen.ns.hetzner.com."
  type    = "NS"
}

resource "hetznerdns_record" "mineshspc_ns_3" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "oxygen.ns.hetzner.com."
  type    = "NS"
}

resource "hetznerdns_record" "mineshspc_com_root" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = hcloud_server.mineshspc.ipv4_address
  type    = "A"
}

resource "hetznerdns_record" "mineshspc_com_mx_1" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "10 aspmx1.migadu.com."
  type    = "MX"
}

resource "hetznerdns_record" "mineshspc_com_mx_2" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "20 aspmx2.migadu.com."
  type    = "MX"
}

resource "hetznerdns_record" "mineshspc_com_spf" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "\"v=spf1 include:spf.migadu.com -all\""
  type    = "TXT"
}

resource "hetznerdns_record" "mineshspc_com_hosted_email_verify" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "@"
  value   = "hosted-email-verify=rp3k5dlz"
  type    = "TXT"
}

resource "hetznerdns_record" "mineshspc_com_dmarc" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "_dmarc"
  value   = "\"v=DMARC1; p=quarantine;\""
  type    = "TXT"
}

resource "hetznerdns_record" "mineshspc_com_cname_autoconfig" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "autoconfig"
  value   = "autoconfig.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_com_srv_autodiscover_tcp" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "_autodiscover._tcp"
  value   = "0 1 443 autodiscover.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "mineshspc_com_srv_imaps_tcp" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "_imaps._tcp"
  value   = "0 1 993 imap.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "mineshspc_com_srv_pop3s_tcp" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "_pop3s._tcp"
  value   = "0 1 995 pop.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "mineshspc_com_srv_submissions_tcp" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "_submissions._tcp"
  value   = "0 1 465 smtp.migadu.com"
  type    = "SRV"
}

resource "hetznerdns_record" "mineshspc_com_cname_domainkey_1" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "key1._domainkey"
  value   = "key1.mineshspc.com._domainkey.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_com_cname_domainkey_2" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "key2._domainkey"
  value   = "key2.mineshspc.com._domainkey.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_com_cname_domainkey_3" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "key3._domainkey"
  value   = "key3.mineshspc.com._domainkey.migadu.com."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_com_cname_sendgrid_em7876" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "em7876"
  value   = "u32104293.wl044.sendgrid.net."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_com_cname_sendgrid_domainkey_1" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "s1._domainkey"
  value   = "s1.domainkey.u32104293.wl044.sendgrid.net."
  type    = "CNAME"
}

resource "hetznerdns_record" "mineshspc_com_cname_sendgrid_domainkey_2" {
  zone_id = hetznerdns_zone.mineshspc_com.id
  name    = "s2._domainkey"
  value   = "s2.domainkey.u32104293.wl044.sendgrid.net."
  type    = "CNAME"
}
