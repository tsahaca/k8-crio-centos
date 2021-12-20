#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the generic/ubuntu2004 Vagrant box
## If you use a different version of Ubuntu or a different Ubuntu Vagrant box test this again
#

##Update the OS
yum update -y
 
## Install yum-utils, bash completion, git, and more
yum install yum-utils nfs-utils bash-completion git -y
 
##Disable firewall starting from Kubernetes v1.19 onwards
systemctl disable firewalld --now
 
 
## letting ipTables see bridged networks
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
 
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
 
##
## iptables config as specified by CRI-O documentation
# Create the .conf file to load the modules at bootup
cat <<EOF | tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF
 
 
modprobe overlay
modprobe br_netfilter
 
 
# Set up required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
 
sysctl --system
 
 
###
## configuring Kubernetes repositories
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
 
## Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 
### Disable swap
swapoff -a
 
##make a backup of fstab
cp -f /etc/fstab /etc/fstab.bak
 
##Renove swap from fstab
sed -i '/swap/d' /etc/fstab
 
 
##Refresh repo list
yum repolist -y
 
 
## Install CRI-O binaries
##########################
 
#Operating system   $OS
#Centos 8   CentOS_8
#Centos 8 Stream    CentOS_8_Stream
#Centos 7   CentOS_7
 
 
#set OS version
OS=CentOS_7
 
#set CRI-O
VERSION=1.22
 
# Install CRI-O
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo
yum install cri-o -y
 
 
##Install Kubernetes, specify Version as CRI-O
yum install -y kubelet-1.22.0-0 kubeadm-1.22.0-0 kubectl-1.22.0-0 --disableexcludes=kubernetes

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
systemctl daemon-reload
systemctl enable crio --now
systemctl enable kubelet --now


# Enable ssh password authentication
echo "[TASK 11] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl reload sshd

# Set Root password
echo "[TASK 12] Set root password"
echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc


echo "[TASK 10] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.57.100   kmaster.example.com     kmaster
192.168.57.101   kworker1.example.com    kworker1
192.168.57.102   kworker2.example.com    kworker2
EOF
