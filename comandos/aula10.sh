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

kubernetes(){
# Escalando privilegios
  sudo su -

# Habilitando repositório
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Desabilitando SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Instalando pacotes necessários
yum install -y kubelet-1.19.3 kubeadm-1.19.3 kubectl-1.19.3 --disableexcludes=kubernetes

# Habilitando kubelet
systemctl enable --now kubelet

# Configurando para o cluster usar o containerd
sed -ri 's,(KUBELET_EXTRA_ARGS=),\1"--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock",' /etc/sysconfig/kubelet

# Reiniciando kubelet
systemctl restart kubelet

# Habilitando bash completion
sudo yum install bash-completion -y
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'source <(kubeadm completion bash)' >>~/.bashrc
source ~/.bashrc

}

$1
