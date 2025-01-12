To automate the process of setting up a Kubernetes cluster using kubeadm in a Linux server, you can create a shell script (setup_kubernetes.sh) to automate the common steps for both master and worker nodes. However, note that certain steps like initializing the master node and joining worker nodes require specific commands or tokens that will need to be manually entered.

## How to use the script:

For Master Node Setup: Run the script on the master node to initialize it:

```bash
sudo bash setup_kubernetes.sh master
```

For Worker Node Setup: After the master node is set up, run this on each worker node to join them to the cluster:

```bash
Copier le code
sudo bash setup_kubernetes.sh worker
```
