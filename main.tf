variable "hcloud_token" {
  sensitive = true
  type      = string
}

variable "hetznerdns_token" {
  sensitive = true
  type      = string
}

# Configure the Hetzner Cloud Provider
terraform {
  required_version = ">= 1.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.38.2"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "2.2.0"
    }
  }

  cloud {
    organization = "nevarro"

    workspaces {
      name = "infrastructure"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hetznerdns_token
}

# SSH Keys
resource "hcloud_ssh_key" "tatooine_ssh_key" {
  name       = "sumner@tatooine"
  public_key = file("./ssh-pubkeys/tatooine.pub")
}

resource "hcloud_ssh_key" "coruscant_ssh_key" {
  name       = "sumner@coruscant"
  public_key = file("./ssh-pubkeys/coruscant.pub")
}

resource "hcloud_ssh_key" "scarif_ssh_key" {
  name       = "sumner@scarif"
  public_key = file("./ssh-pubkeys/scarif.pub")
}

# Firewalls
resource "hcloud_firewall" "web_server_firewall" {
  name = "web-server"

  rule {
    description = "ping"
    direction   = "in"
    protocol    = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "HTTP"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    description = "HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# Private Networks
resource "hcloud_network" "nevarro_network" {
  name     = "nevarro"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "nevarronet" {
  network_id   = hcloud_network.nevarro_network.id
  type         = "cloud"
  network_zone = "us-east"
  ip_range     = "10.0.1.0/24"
}
