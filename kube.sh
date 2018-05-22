#!/bin/bash


set -x
flannel=https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
sudo swapoff -a
sudo sysctl net.bridge.bridge-nf-call-iptables=1
cip=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
ktoken=b0d383.4b60ff7a44bc6642
kip=192.168.15.136
kport=6443 
khash=7d45e65a56c738b0e3d70dd3f1de1d97c579c444ac00dccd4b17b69251d498b6
install_docker() {
  sudo apt-get update
  sudo apt-get install \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  sudo apt-get update && sudo apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
  sudo groupadd docker
  sudo gpasswd -a $USER docker
  sudo docker run -d -p 5000:5000 --restart=always --name="my_image" -v /opt/data/registry:/registry -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/registry registry
}

install_kube() {
  sudo apt-get update && sudo apt-get install -y apt-transport-https
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list
  sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
}

set_kubelet() {
  sudo sed -i "s,ExecStart=$,Environment=\"KUBELET_EXTRA_ARGS= --address=0.0.0.0 --port=10250 --fail-swap-on=false --pod-infra-container-image=gcr.io/google_containers/pause-amd64:3.1\"\nExecStart=,g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
}

set_image() {
  if [ $# -eq 1 ]
  then
    sudo docker build -t $1 ./$1/
    sudo docker tag $1:latest $cip:5000/$1:latest
    sudo docker push $cip:5000/$1:latest
  else
	echo "No argument supplied"
  fi
}

set_kubectl() {
  mkdir -p $HOME/.kube
  sudo cp -rf -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

set_flannel() {
  sudo kubectl apply -f $flannel
}

shutdown_kubeadm() {
	sudo kubectl --namespace kube-system delete service kubernetes-dashboard
	sudo kubectl --namespace kube-system delete deployment kubernetes-dashboard
	servs=($(echo $(sudo kubectl get services -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}') | tr ' ' '\n'))
	for serv in "${servs[@]}"
	do
    	sudo kubectl delete service $serv
	done
	deps=($(echo $(sudo kubectl get deployments -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}') | tr ' ' '\n'))
	for dep in "${deps[@]}"
	do
    	sudo kubectl delete deployment $dep
	done
	nodes=($(echo $(sudo kubectl get nodes -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}') | tr ' ' '\n'))
	for node in "${nodes[@]}"
	do
    	sudo kubectl drain $node --delete-local-data --force --ignore-daemonsets
  		sudo kubectl delete node $node
	done
	sudo kubeadm reset
}

case "$1" in
  "install_docker")
    install_docker
    ;;
  "install_kube")
    install_kube
    ;;
  "set_kubelet")
    set_kubelet
    ;;
  "set_image")
    set_image $2
    ;;
  "master")
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16
    ;;
  "node")
    sudo kubeadm join --token $ktoken $kip:$kport --discovery-token-ca-cert-hash sha256:$khash
    ;;
  "conf")
    set_kubectl
    set_flannel
	  sudo kubectl taint nodes --all node-role.kubernetes.io/master-
	  sudo kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
	  sudo kubectl create -f user.yaml
	  sudo kubectl create -f access.yaml
	  sudo kubectl create -f pv.yaml
	  # sudo kubectl create -f pv-nfs.yaml
	  sudo kubectl create -f pvc.yaml
	  sudo kubectl -n kube-system describe secret $(sudo kubectl -n kube-system get secret | grep kubernetes-dashboard-head | awk '{print $1}') >> token
	  sudo kubectl proxy &
    ;;
  "close")
    shutdown_kubeadm
    ;;
  *)
    echo "invalid command"
    ;;
esac
