variable "hcloud_token" {
  sensitive = true
  type      = string
}

# Configure the Hetzner Cloud Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.2"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
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
