#############################
#Install Azure CLI
#############################
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
Remove-Item -Path .\AzureCLI.msi

#############################
#Install Git - https://git-scm.com/download/win
#############################

#############################
#Install VS Code - https://code.visualstudio.com/Download
#############################


#############################
#Install Docker - https://docs.docker.com/desktop/windows/install/#install-docker-desktop-on-windows
# Need to figure out how to do this in quiet mode
#############################
# Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
# Install-Package -Name docker -ProviderName DockerMsftProvider
# #  A restart is required to enable the containers feature. *** Restart the machine***
# Start-Service Docker

#############################
# Install Kubectl -  https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# BTW, Docker Desktop adds its own version of kubectl to PATH as well
#############################
# curl -LO "https://dl.k8s.io/release/v1.23.0/bin/windows/amd64/kubectl.exe"
# Install-Script -Name 'install-kubectl' -Scope CurrentUser -Force
# install-kubectl.ps1 -DownloadLocation ./


#############################
#Install Helm : https://helm.sh/docs/intro/install/
#############################


#############################
#Install OC CLI : https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-windows.zip
#############################