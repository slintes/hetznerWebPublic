#!/usr/bin/env bash

set -e

# terraform
(
  cd tf

  #terraform init

  #echo "Destroying old cluster"
  #terraform destroy

  echo "Creating new cluster"
  terraform apply
)

# update configs
export FLOAT_IP_01=$(jq -r '.resources[] | select(.type == "hcloud_floating_ip" and .name == "ingress") | .instances[0].attributes.ip_address' tf/terraform.tfstate)
export MASTER_IP_01=$(jq -r '.resources[] | select(.type == "hcloud_server" and .name == "nodes") | .instances[] | select(.index_key == "node01") | .attributes.ipv4_address' tf/terraform.tfstate)
export WORKER_IP_01=$(jq -r '.resources[] | select(.type == "hcloud_server" and .name == "nodes") | .instances[] | select(.index_key == "node02") | .attributes.ipv4_address' tf/terraform.tfstate)
export WORKER_IP_02=$(jq -r '.resources[] | select(.type == "hcloud_server" and .name == "nodes") | .instances[] | select(.index_key == "node03") | .attributes.ipv4_address' tf/terraform.tfstate)
export WORKER_IP_03=$(jq -r '.resources[] | select(.type == "hcloud_server" and .name == "nodes") | .instances[] | select(.index_key == "node04") | .attributes.ipv4_address' tf/terraform.tfstate)

echo "Floating IP: ${FLOAT_IP_01}" | tee ips.txt
echo "Master IP: ${MASTER_IP_01}" | tee -a ips.txt
echo "Worker 1 IP: ${WORKER_IP_01}" | tee -a ips.txt
echo "Worker 2 IP: ${WORKER_IP_02}" | tee -a ips.txt
echo "Worker 3 IP: ${WORKER_IP_03}" | tee -a ips.txt

(
  cd kubespray

  # prepare inventory
  echo "Preparing inventory"
  cat inventory/mycluster/hosts.yaml.in | envsubst > inventory/mycluster/hosts.yaml

  # configure floating IP
  echo "Configuring floating IP"
  cat inventory/mycluster/group_vars/all/floating-ips.yml.in | envsubst > inventory/mycluster/group_vars/all/floating-ips.yml
  ansible-playbook --flush-cache -i inventory/mycluster/hosts.yaml configure-floating-ip.yml

  # install k8s
  echo "Installing k8s"
  ansible-playbook --flush-cache -i inventory/mycluster/hosts.yaml cluster.yml

  # set public master IP in admin.conf
  sed -i -E "s|(https?://).*(:)|\1${MASTER_IP_01}\2|g" inventory/mycluster/artifacts/admin.conf

)

export KUBECONFIG=/home/msluiter/dev/private/hetznerWeb/init/kubespray/inventory/mycluster/artifacts/admin.conf

(
  # install metallb
  echo "Installing MetalLB"

  cd metallb
  cat config.yml.in | envsubst > config.yml

  kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
  sleep 10
  kubectl apply -f .

)

(

  # install ingress controller
  echo "Installing Nginx Ingress Controller"
  cd nginx
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml
  # use LoadBalancer service, will be served by metallb
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/cloud-generic.yaml

  # config
  kubectl apply -f .

)

(

  # cert-manager
  echo "Installing cert-manager"
  cd certmanager
  kubectl create namespace cert-manager
  kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
  sleep 20

  # Issuers
  kubectl apply -f .

)

(

  # Rook
  echo "Installing Rook"
  cd rook
  kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-1.2/cluster/examples/kubernetes/ceph/common.yaml
  kubectl apply -f https://raw.githubusercontent.com/rook/rook/release-1.2/cluster/examples/kubernetes/ceph/operator.yaml
  kubectl apply -f .

  sleep 20

)

(

  # test deployment
  echo "Deploying test app"
  kubectl apply -f test

  echo "open https://test.k8s.slintes.dev in browser"

)

