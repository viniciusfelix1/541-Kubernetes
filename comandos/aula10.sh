#!/bin/bash
## Este script irá executar comandos utilizados na aula 10 do curso.

containerd() {
# Criando arquivo para carregar os módulos necessários.
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# Carregando módulos
sudo modprobe overlay
sudo modprobe br_netfilter

# Habilitando alguns parâmetros do kernel.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Aplicando parâmtros
sudo sysctl --system

# Instalando dependências
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# Ativando repo do docker
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Instalando containerd.io
sudo yum update -y && sudo yum install -y containerd.io

# Criando diretório de configuração
sudo mkdir -p /etc/containerd

# Gerando arquivo de configuração do containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Habilitando e iniciando serviço
sudo systemctl enable --now containerd
sudo systemctl restart containerd
}

$1
