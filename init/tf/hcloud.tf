# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {}

variable "my_net_range" {}
variable "my_subnet_01_range" {}

variable "server_location" {}
variable "server_image" {}

variable "nodes" {
  type = map(object({
    ip = string
    type = string
  }))
}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = var.hcloud_token
}

# Create a new SSH key
resource "hcloud_ssh_key" "k8s" {
  name = "K8s SSH Key"
  public_key = file("~/.ssh/hetzner-k8s.pub")
}

# Private network config
resource "hcloud_network" "mynet" {
  name = "my-net"
  ip_range = var.my_net_range
}

resource "hcloud_network_subnet" "mysubnet_1" {
  network_id = hcloud_network.mynet.id
  type = "server"
  network_zone = "eu-central"
  ip_range = var.my_subnet_01_range
}

# Server config
resource "hcloud_server" "nodes" {
  for_each = var.nodes
  name = each.key
  ssh_keys = [hcloud_ssh_key.k8s.id]
  location = var.server_location
  image = var.server_image
  server_type = each.value.type
  keep_disk = true
  backups = true
}

# Assign private IP to server
resource "hcloud_server_network" "srvnetwork" {
  for_each = var.nodes
  server_id = hcloud_server.nodes[each.key].id
  network_id = hcloud_network.mynet.id
  ip = each.value.ip
}


# Floating IP for ingress to node01
resource "hcloud_floating_ip" "ingress" {
  type = "ipv4"
  home_location = var.server_location
}

resource "hcloud_floating_ip_assignment" "ingress" {
  floating_ip_id = hcloud_floating_ip.ingress.id
  server_id = hcloud_server.nodes["node02"].id
}
