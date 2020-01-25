#hcloud_token = "<YOUR_HETZNER_CLOUD_PROJECT_TOKEN>"

my_net_range = "172.16.0.0/12"
my_subnet_01_range = "172.30.30.0/24"

server_location = "fsn1"
server_image = "centos-7"

nodes= {
    node01 = {
        ip = "172.30.30.51"
        type = "cx31"
    },
    node02 = {
        ip = "172.30.30.52"
        type = "cx31"
    },
    node03 = {
        ip = "172.30.30.53"
        type = "cx31"
    },
    node04 = {
        ip = "172.30.30.54"
        type = "cx31"
    },
}
