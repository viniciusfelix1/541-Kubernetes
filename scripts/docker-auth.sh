#!/bin/bash
#
# Para pleno funcionamento, é utilizado a infraestrutura criada pelo curso 541 - Kubernetes da 4linux.
## https://github.com/4linux/4541
#
# Este script irá copiar o arquivo 'config.json' com a credencial de acesso ao https://hub.docker.com/ para os nós do cluster.
#
# Para utilização, é necessário ter o arquivo já criado, caso não tenha, acesso a máquina 'kube-master' e rode o comando "docker login" através do usuário 'suporte'.
## vagrant ssh kube-master
## sudo -i -u suporte
## docker login
#

echo "Buscando arquivo com as credenciais..."
vagrant ssh kube-master -c "sudo -u suporte cat /home/suporte/.docker/config.json" > config.json

echo "Enviando arquivo para as VMs..."
vagrant rsync

for NODE in $(vagrant status | awk '/node/ {print $1}'); do
  echo "Enviando arquivo para: ${NODE}"
  vagrant ssh ${NODE} -c 'sudo cp /vagrant/config.json /var/lib/kubelet/config.json'
done
