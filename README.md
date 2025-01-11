# **Kubernetes Installation Guide**

This guide provides a step-by-step process for setting up a Kubernetes cluster in a production environment on a **Linux server** with **active swap**. It covers the installation and configuration of Kubernetes components, as well as the setup of both master and worker nodes using `kubeadm`.

This guide assumes you are working in an environment where swap is enabled but will walk you through disabling it temporarily for Kubernetes initialization. Afterward, you will learn how to set up the cluster components and join the worker nodes to the master node.

---

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
  - [Common Steps for Master and Worker Nodes](#common-steps-for-master-and-worker-nodes)
  - [Master Node Setup](#master-node-setup)
  - [Worker Node Setup](#worker-node-setup)
  - [Master Node Verification](#master-node-verification)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Introduction

This guide will walk you through the steps required to install Kubernetes on a Linux server. It is suitable for both beginner and advanced users who wish to set up a production-ready Kubernetes cluster.

## Prerequisites

- A Linux-based server (Ubuntu, CentOS, etc.)
- At least one master node and one worker node
- Sudo privileges on each server

## Installation Steps

### Common Steps for Master and Worker Nodes

#### **1. Installing a Container Runtime (Common Step)**

Install and configure `containerd` as the container runtime:

```bash
sudo apt install containerd -y
```

Generate the default configuration and update it to use `SystemdCgroup`:

```bash
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
```

---

#### **2. Installing kubeadm, kubelet, and kubectl (Common Step)**

##### **Add Kubernetes Package Repository**

Update package sources and install required dependencies:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
```

Add the Kubernetes repository signing key and repository:

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

##### **Install Kubernetes Tools**

```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
```

---

#### **3. Enable IPv4 Packet Forwarding (Common Step)**

Set up packet forwarding for IPv4:

```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

---

#### **4. Disable Swap Temporarily Before starting the Kubernetes installation (Common Step)**

Disable swap temporarily to meet Kubernetes requirements:

```bash
sudo swapoff -a
```

---

### Master Node Setup

#### **5. Master Node Setup with Calico (Master Only)**

##### **Initialize the Control Plane (Master Only)**

Run the `kubeadm init` command for the master node:

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

##### **Configure kubectl Access (Master Only)**

Set up `kubectl` for the current user on the master node:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

#### **6. Enable Swap After initializing the control plane (Master Only)**

If enabling swap, modify the Kubelet configuration:

1. Edit `/var/lib/kubelet/config.yaml`:

   ```yaml
   failSwapOn: false
   memorySwap:
     swapBehavior: "LimitedSwap"
   ```

2. Restart the kubelet service:

   ```bash
   sudo systemctl restart kubelet
   ```

---

#### **7. Installing a Pod Network Add-on (Master Only)**

Install Calico as the pod network add-on:

1. Deploy the Tigera Calico operator:

   ```bash
   kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
   ```

2. Create custom resources for Calico:

   ```bash
   kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml
   ```

3. Monitor the deployment:

   ```bash
   watch kubectl get pods -n calico-system
   ```

4. Remove taints on the control plane to schedule pods on it:

   ```bash
   kubectl taint nodes --all node-role.kubernetes.io/control-plane-
   ```

---

### Worker Node Setup

#### **8. Join Worker Nodes to the Cluster (Worker Only)**

After initializing the master node, use the command returned by `kubeadm init` to join the worker nodes:

```bash
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

If you lost the command to join the worker you can got it by running the following command in the master

```bash
kubeadm token create --print-join-command
```

---

#### **9. Enable Swap After initializing the control plane (Worker Only)**

If enabling swap, modify the Kubelet configuration:

1. Edit `/var/lib/kubelet/config.yaml`:

   ```yaml
   failSwapOn: false
   memorySwap:
     swapBehavior: "LimitedSwap"
   ```

2. Restart the kubelet service:

   ```bash
   sudo systemctl restart kubelet
   ```

---

### Master Node Verification

#### **10. Final Verification (Master Only)**

Check the nodes in your cluster:

```bash
kubectl get nodes -o wide
kubectl get pods -A
```

---

### **Key Highlights for Master and Worker Nodes:**

- **Master Node:**

  - Run `kubeadm init` to initialize the cluster.
  - Set up `kubectl` for the master node and configure the kubelet.
  - Install Calico and configure the control plane.

- **Worker Nodes:**
  - Use the `kubeadm join` command provided by the master node to join the cluster.
  - Workers also need `containerd`, `kubeadm`, `kubelet`, and `kubectl` installed.
