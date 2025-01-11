#!/bin/bash

# Variables (Customize as needed)
K8S_VERSION="1.21.0"       # Kubernetes version
MASTER_IP="your_master_ip" # Replace with your master node IP for worker node join
POD_NETWORK_CIDR="192.168.0.0/16"
KUBEADM_TOKEN=$(kubeadm token create --print-join-command)

# 1. Installing a Container Runtime (Common Step)
echo "Installing containerd..."
sudo apt update
sudo apt install -y containerd

# Configure containerd
echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# 2. Installing kubeadm, kubelet, kubectl (Common Step)
echo "Installing kubeadm, kubelet, and kubectl..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

# 3. Enable IPv4 Packet Forwarding (Common Step)
echo "Enabling IPv4 packet forwarding..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# 4. Disable Swap Temporarily Before starting Kubernetes Installation (Common Step)
echo "Disabling swap temporarily..."
sudo swapoff -a

# 5. Master Node Setup (Only for Master Node)
if [ "$1" == "master" ]; then
    echo "Initializing the Kubernetes master node..."
    sudo kubeadm init --pod-network-cidr=$POD_NETWORK_CIDR

    echo "Configuring kubectl for master node..."
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "Enabling swap after master initialization..."
    sudo swapon -a

    # Modify the Kubelet Config File to allow swap
    echo "Configuring Kubelet to allow limited swap..."
    sudo sed -i 's/^\(failSwapOn:\).*/\1 false/' /var/lib/kubelet/config.yaml
    echo -e "memorySwap:\n  swapBehavior: \"LimitedSwap\"" | sudo tee -a /var/lib/kubelet/config.yaml

    echo "Restarting Kubelet..."
    sudo systemctl restart kubelet

    # Installing Pod Network Add-on (Calico)
    echo "Installing Calico network addon..."
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml

    echo "Waiting for Calico pods to be running..."
    watch kubectl get pods -n calico-system

    # Remove taints on control plane node
    echo "Removing taints from master node..."
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-

    echo "Master node setup complete."

# 6. Worker Node Setup (Only for Worker Node)
elif [ "$1" == "worker" ]; then
    echo "Joining the worker node to the Kubernetes cluster..."
    if [ -z "$KUBEADM_TOKEN" ]; then
        echo "ERROR: Kubernetes join token not available. Please run the master setup first."
        exit 1
    fi

    sudo kubeadm join $MASTER_IP:6443 --token $KUBEADM_TOKEN

    echo "Worker node joined to the cluster."
else
    echo "Invalid argument. Use 'master' to set up the master node or 'worker' to join a worker node."
    exit 1
fi

# 7. Final Verification
echo "Checking the status of the Kubernetes cluster..."
kubectl get nodes -o wide
kubectl get pods -A

echo "Kubernetes installation complete."
