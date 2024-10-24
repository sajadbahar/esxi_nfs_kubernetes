
# ESXi NFS Kubernetes Setup

This project provides a comprehensive guide to setting up a **Kubernetes Cluster** on **ESXi** using **NFS** as the storage provider. The setup is designed for a self-hosted environment where VMs are provisioned on ESXi, and NFS is used to persist data for Kubernetes workloads.

## Prerequisites

Before you begin, ensure that you have the following prerequisites:

- **ESXi**: A running instance of **VMware ESXi** (v6.7 or later recommended).
- **NFS Server**: An available **NFS server** for persistent storage (can be hosted on one of the VMs or a separate server).
- **VMs for Kubernetes**: At least 5 VMs (2 master nodes and 3 worker nodes) provisioned with:
  - Ubuntu 20.04 LTS or similar.
  - 2 CPU cores and 4GB+ RAM (per VM).
- **Kubeadm, Kubectl, Kubelet**: Installed on each node.
- **NFS Client**: Installed on each node to mount the NFS share.
- **Helm**: Optional, for easier application deployments.

## Project Overview

- **VMWare ESXi**: Used to run the VMs for Kubernetes cluster.
- **NFS**: Used as the persistent storage backend for Kubernetes.
- **Kubernetes**: The container orchestration platform.
- **MetalLB**: LoadBalancer solution for bare-metal Kubernetes.
- **Ingress NGINX**: Handles HTTP routing into the Kubernetes cluster.

## Architecture

- **2 Master Nodes**: Control plane for the Kubernetes cluster.
- **3 Worker Nodes**: Runs containerized applications.
- **NFS Server**: Provides persistent storage via NFS for Kubernetes workloads.

## Installation Steps

### Step 1: Set Up VMs on ESXi

1. **Provision the VMs** for Kubernetes (2 master nodes and 3 worker nodes) on your ESXi server.
2. Ensure that each VM has a static IP address and sufficient resources (2 CPU cores, 4GB RAM, and 20GB disk space recommended).

### Step 2: Install NFS Server

1. On your **NFS server VM**, install the NFS server:

   ```bash
   sudo apt update
   sudo apt install nfs-kernel-server
   ```

2. Create the directory to share:

   ```bash
   sudo mkdir -p /srv/nfs/k8s
   ```

3. Set the correct permissions:

   ```bash
   sudo chown nobody:nogroup /srv/nfs/k8s
   sudo chmod 777 /srv/nfs/k8s
   ```

4. Edit the NFS exports file:

   ```bash
   sudo nano /etc/exports
   ```

   Add the following line to export the directory:

   ```bash
   /srv/nfs/k8s <client-IP>(rw,sync,no_subtree_check,no_root_squash)
   ```

5. Export the directory and restart the NFS server:

   ```bash
   sudo exportfs -ra
   sudo systemctl restart nfs-kernel-server
   ```

### Step 3: Install Kubernetes on VMs

1. SSH into each **master** and **worker** node and install **Kubeadm, Kubectl, and Kubelet**:
   
   ```bash
   sudo apt update
   sudo apt install -y apt-transport-https curl
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
   echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
   sudo apt update
   sudo apt install -y kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   ```

2. Disable swap:

   ```bash
   sudo swapoff -a
   ```

3. Initialize Kubernetes on the **first master node**:

   ```bash
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16
   ```

4. Follow the instructions to set up `kubectl` on the master node and join worker nodes:

   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

5. Install a **CNI (Calico)** for networking:

   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

6. Join worker nodes to the cluster using the command provided after `kubeadm init`.

### Step 4: Set Up NFS in Kubernetes

1. **Create a PersistentVolume (PV) for NFS**:

   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: nfs-pv
   spec:
     capacity:
       storage: 10Gi
     accessModes:
       - ReadWriteMany
     nfs:
       path: /srv/nfs/k8s
       server: <nfs-server-ip>
   ```

2. **Apply the PV**:

   ```bash
   kubectl apply -f nfs-pv.yaml
   ```

3. **Create a PersistentVolumeClaim (PVC)**:

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: nfs-pvc
   spec:
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 5Gi
   ```

4. **Apply the PVC**:

   ```bash
   kubectl apply -f nfs-pvc.yaml
   ```

### Step 5: Install MetalLB

1. Install **MetalLB** for LoadBalancer functionality in a bare-metal environment:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
   ```

2. Create a **MetalLB ConfigMap** with your IP range:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     namespace: metallb-system
     name: config
   data:
     config: |
       address-pools:
       - name: default
         protocol: layer2
         addresses:
         - 192.168.1.240-192.168.1.250
   ```

3. Apply the ConfigMap:

   ```bash
   kubectl apply -f metallb-config.yaml
   ```

### Step 6: Set Up Ingress Controller

1. Install **NGINX Ingress**:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
   ```

2. Verify that the NGINX Ingress controller is running:

   ```bash
   kubectl get pods -n ingress-nginx
   ```

## Usage

Once everything is set up, you can start deploying your applications on Kubernetes, using NFS as persistent storage and MetalLB to handle LoadBalancer services.

## Troubleshooting

- **Nodes Not Ready:** Ensure networking (Calico) is correctly installed.
- **NFS Mount Issues:** Check permissions on the NFS server and ensure clients can access the NFS share.

## Contributions

Feel free to submit pull requests if you have improvements or find issues!

## License

This project is licensed under the MIT License.
