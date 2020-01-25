# Hetzner Cloud K8s

This installs a 4 node (1 master, 3 workers) k8s cluster on Hetzner Cloud using CentOS 7 VMs.

## Initial installation

Terraform + Ansible + KubeSpray + MetalLB + K8s Nginx ingress Controller + Cert Manager + Rook
 
See [init/README.md](init/README.md)

## Apps

Mysql + PhpMyAdmin + Wordpress + some custom deployments

See /apps

## Backup

- Rook / PVs: TODO
- MySql: TODO
- nodes: automatic backup once a day by Hetzner
