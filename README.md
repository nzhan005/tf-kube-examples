# tf-kube-examples

## VERSION INFO
* platform: ubuntu 16.04.3
* docker: 17.03
* kube-tools: 1.9.3


## HOW TO USE
```
chmod 777 ./kube.sh

# Install docker
sudo ./kube.sh install_docker

# Install kube
sudo ./kube.sh install_kube

# Configure kubelet
sudo ./kube.sh set_kubelet

# Configure image (master only)
sudo ./kube.sh set_image <image_name>

# Start master node (master only)
# Record the output from terminal for node joining.
sudo ./kube.sh master

# Start slave node (slave only)
# Must change ktoken, kip, kport ,khash to the corresponding output from master node first.
sudo ./kube.sh node

# Configure kubectl & network & dashboard (master only)
# Use the output token from token file for logging into dashboard.
sudo ./kube.sh conf

# Shutdown cluster & clean (master only)
sudo ./kube.sh close
```

#### ENABLE DASHBOARD
When master node is up and configuration is done, now access Dashboard at:
[Open in browser](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/)

Copy the token from token file to login screen and click log in.

#### PREPARE DATA
Move the train/test data into /tmp/data folder.
```
sudo mv -f <data> /tmp/data
```

#### RUN

```
# run retrain
sudo kubectl create -f retrain.yaml

# run inference
sudo kubectl create -f infer.yaml
```

## SOME USEFUL COMMANDS
```
sudo kubectl get pods # check pods
sudo kubectl get pods --all-namespaces # check system status
sudo kubectl get deployments # check deployments
sudo kubectl get services # check services
sudo kubectl get pv <pv>  # check persistent volume <pv>
sudo kubectl get pvc <pvc> # check persistent volume claim <pvc>
sudo kubectl logs <pod> # check pod running log
sudo kubectl describe pod <pod> # check pod status
sudo kubectl expose deployment <dep> # create service, not used locally
journalctl -u kubelet # check kubelet log

```
