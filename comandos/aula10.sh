#!/bin/bash
## Este script irá executar comandos utilizados na aula 10 do curso.
## No momento funciona apenas em servidores centos.

help(){
echo -e "Sintaxe"
echo -e "\t$0 [OPÇÕES]\n"
echo -e "Este script pode configurar o containerd, os componentes de um cluster do kubernetes e também o o control plane. No momento está funcinando apenas em servidores centos.\n"
echo -e "Opções:\ncontainerd\t Irá instalar e habilitar o containerd.\nkubernetes\t Irá instalar as ferramentas kubectl, kubeadm e irá subir o kubelet.\ncontrol-plane\t Irá configurar o control plane do kubernetes através do kubeadm.\n"
}

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
# Desabilitando swap
sudo sed -Ei 's/(.*swap.*)/#\1/g' /etc/fstab
sudo swapoff -a
# Habilitando repositório
  cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
# Desabilitando SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
# Instalando pacotes necessários
sudo yum install -y kubelet-1.20.7 kubeadm-1.20.7 kubectl-1.20.7 --disableexcludes=kubernetes
# Habilitando kubelet
sudo systemctl enable --now kubelet
# Configurando para o cluster usar o containerd
sudo sed -ri 's,(KUBELET_EXTRA_ARGS=),\1"--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock",' /etc/sysconfig/kubelet
# Reiniciando kubelet
sudo systemctl restart kubelet
# Habilitando bash completion
sudo yum install bash-completion -y
source /usr/share/bash-completion/bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'source <(kubeadm completion bash)' >>~/.bashrc
source ~/.bashrc
}

control-plane(){
# Baixando imagens
sudo kubeadm config images pull --kubernetes-version=1.20.7
# Iniciando cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/16   --apiserver-advertise-address=172.16.1.100 --kubernetes-version=1.20.7   --ignore-preflight-errors=all
# Colocando config para comunicação com o cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# Aplicando manifestos de rede
kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml
}

case $1 in
  containerd|kubernetes|control-plane)
    $1
;;
  *)
    help
esac
