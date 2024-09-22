#!/bin/bash

# Function to log commands and their output
log_command() {
    echo "$ $@" >> $logpath
    eval "$@" 2>&1 | tee -a $logpath
    echo "" >> $logpath
}

#############################
# Script Definition
sudo touch /var/log/deploymentscriptlog
sudo chown arolzauser:arolzauser /var/log/deploymentscriptlog
logpath=/var/log/deploymentscriptlog

echo "Script started" >> $logpath
echo "" >> $logpath

#############################
#Install Misc Tools
#############################
log_command echo "#############################"
log_command echo "Installing Misc Tools"
log_command echo "#############################"
log_command sudo apt-get update
log_command sudo apt-get install -y apt-transport-https ca-certificates curl vim git

#############################
#Install Azure CLI
#############################
log_command echo "#############################"
log_command echo "Installing Azure CLI"
log_command echo "#############################"
log_command curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#############################
#Install Docker
#############################
log_command echo "#############################"
log_command echo "Installing Docker"
log_command echo "#############################"
log_command sudo apt install -y docker.io

#############################
#Install Kubectl
#############################
log_command echo "#############################"
log_command echo "Installing Kubectl"
log_command echo "#############################"
log_command curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
log_command sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

#############################
#Install Helm
#############################
log_command echo "#############################"
log_command echo "Installing Helm"
log_command echo "#############################"
log_command curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
log_command echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
log_command sudo apt-get update
log_command sudo apt-get install helm

#############################
#Install OC CLI
#############################
log_command echo "#############################"
log_command echo "Installing OC"
log_command echo "#############################"
log_command wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
log_command tar -zxvf openshift-client-linux.tar.gz
log_command sudo mv oc /usr/local/bin
log_command rm README.md
log_command rm kubectl
log_command rm openshift-client-linux.tar.gz

#############################
#Upgrade packages
#############################
log_command echo "#############################"
log_command echo "Upgrading Packages"
log_command echo "#############################"
log_command sudo apt upgrade -y

echo "Script completed" >> $logpath