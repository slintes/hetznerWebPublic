# Init k8s cluster

## Network setup

### Network 172.16.0.0/12  

Netmask	255.240.0.0  
Wildcard Bits	0.15.255.255  
First IP	172.16.0.0  
Last IP	    172.31.255.255  

### Subnet 172.30.30.0/24  

Netmask	255.255.255.0  
Wildcard Bits	0.0.0.255  
First IP	172.30.30.0  
Last IP	    172.30.30.255  

### Private node IPs  

Configured by terraform and ansible, but see also https://wiki.hetzner.de/index.php/Cloud_Networks_Configuration/en#Manual_configuration_of_alias_IPs

node01 172.30.30.51  
node02 172.30.30.52  
node03 172.30.30.53  

## Install all by script

All following steps can be executed automatically by running `./create.sh`

ATTENTION: this will potentially delete an old cluster!

## VM management with terraform

https://www.terraform.io/docs/providers/hcloud/index.html

### Create

    cd tf  
    terraform init  
    terraform show  
    terraform apply  

### Destroy

    terraform destroy  

### Before going on:

- set VM IPs in kubespray `hosts.yaml`
- set Floating IP(s) in kubespray `floating-ips.yml`  
- set Floating IP(s) in `metallb/config.yaml`

## Configure floating ip on worker nodes

https://wiki.hetzner.de/index.php/Cloud_floating_IP_persistent/en

    $ ansible-playbook -i inventory/mycluster/hosts.yaml configure-floating-ip.yml

# Install k8s with KubeSpray

https://github.com/kubernetes-sigs/kubespray  
Release v2.12.0  
K8s 1.16.3  

in `all.yml`
- when 1 master: loadbalancer_apiserver_localhost: false  // NO, DOES NOT WORK, KUBE-PROXY IS MISCONFIGURED THEN, SO KEEP THIS TO TRUE

in `k8s-cluster.yml`
- kube_proxy_mode: iptables
- kube_proxy_strict_arp: true
- kube_network_plugin: flannel

in `addons.yml`
- enable metrics  
- no ingress, no certmanager (prefer to install all by myself in following steps)

optional (needed when using low NodePorts for e.g. the Ingress Controller, but not if using MetalLB):
- create `node-port-range.yml` with `kube_apiserver_node_port_range: "80-32767"`

extend inventory, e.g.:

    node1:
      ansible_host: <PUBLIC_IP>
      ansible_user: root
      ansible_ssh_private_key_file: ~/.ssh/hetzner-k8s.key
      ip: <PRIVATE_IP>
      access_ip: <PRIVATE_IP>

run playbook without `--become*` flags (not needed, we are root already)

    $ ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml

find admin.conf in artifacts, replace master IP with public IP

# Install MetalLB

https://metallb.universe.tf/installation/

update floating IP in `metallb/config.yaml` and apply

# Install ingress controller

NOPE, DID NOT WORK FOR ME... https://docs.solo.io/gloo/latest/installation/ingress/

https://kubernetes.github.io/ingress-nginx/deploy/

Use GCE / GKE / Azure / cloud generic service:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml

config options;
https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/nginx-configuration/configmap.md

    kubectl apply -f nginx
    
# Install cert-manager

https://cert-manager.io/docs/installation/kubernetes/  

install issuer(s):
    
    kubectl apply -f certmanager

# Storage: Rook

    kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-1.2/cluster/examples/kubernetes/ceph/common.yaml
    kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-1.2/cluster/examples/kubernetes/ceph/operator.yaml
    kubectl apply -f rook/cluster.yml

# Test deployment

    k apply -f test
    
 
