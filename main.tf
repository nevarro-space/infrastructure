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
