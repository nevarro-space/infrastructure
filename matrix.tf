// Matrix Server
resource "hcloud_server" "matrix" {
  name        = "matrix"
  image       = "ubuntu-22.04"
  server_type = "ccx22"
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

output "matrix_server_ipv4" {
  value = hcloud_server.matrix.ipv4_address
}

output "matrix_server_ipv6" {
  value = hcloud_server.matrix.ipv6_address
}

resource "hcloud_volume" "matrix-postgres-data" {
  name     = "matrix-postgres-data"
  size     = 150
  location = "ash"
  format   = "ext4"
}

output "matrix_server_postgresql_data_linux_device" {
  value = hcloud_volume.matrix-postgres-data.linux_device
}

resource "hcloud_volume_attachment" "main" {
  volume_id = hcloud_volume.matrix-postgres-data.id
  server_id = hcloud_server.matrix.id
  automount = true
}

resource "hcloud_server_network" "matrix_nevarronet" {
  server_id  = hcloud_server.matrix.id
  network_id = hcloud_network.nevarro_network.id
  ip         = "10.0.1.3"
}

output "matrix_server_internal_ip" {
  value = hcloud_server_network.matrix_nevarronet.ip
}

resource "hetznerdns_record" "nevarro_space_a_matrix" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "matrix"
  value   = hcloud_server.matrix.ipv4_address
  type    = "A"
}

resource "hetznerdns_record" "nevarro_space_a_meetbot" {
  zone_id = hetznerdns_zone.nevarro_space.id
  name    = "meetbot"
  value   = hcloud_server.matrix.ipv4_address
  type    = "A"
}
