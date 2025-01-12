```bash
## Reset the Kubernetes Cluster

sudo kubeadm reset -f

## Remove Kubernetes Components

sudo apt-get purge -y kubeadm kubectl kubelet kubernetes-cni
sudo apt-get autoremove -y

## Remove Container Runtime

sudo apt-get purge -y containerd
sudo apt-get autoremove -y
sudo rm -rf /etc/containerd

## Clean Up System Configuration

# Kubernetes-related configuration and logs

sudo rm -rf ~/.kube /etc/kubernetes /var/lib/etcd /var/lib/kubelet /var/lib/dockershim /var/run/kubernetes
sudo rm -rf /etc/cni /opt/cni /var/lib/cni

# System configurations

sudo rm -rf /etc/sysctl.d/k8s.conf

sudo sysctl --system

## Uninstall Network Plugin

kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml

## Clean Firewall Rules

sudo ufw delete allow 6443
sudo ufw delete allow 2379:2380/tcp
sudo ufw delete allow 10250
sudo ufw delete allow 10251
sudo ufw delete allow 10252

## Verify Cleanup

# Check if kubeadm, kubectl, and kubelet are still present

which kubeadm
which kubectl
which kubelet

# Ensure no Kubernetes processes are running

ps aux | grep kube

```
