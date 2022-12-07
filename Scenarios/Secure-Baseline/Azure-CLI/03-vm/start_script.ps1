$scriptblock = {
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-ExecutionPolicy Unrestricted -File `"$PSCommandPath`"" -Verb RunAs; exit }

    # Creating InstallDir
    $Downloaddir = "C:\InstallDir"
    if ((Test-Path -Path $Downloaddir) -ne $true) {
        mkdir $Downloaddir
    }
    Set-Location $Downloaddir

    Start-Transcript ($Downloaddir+".\InstallPSScript.log")

    function Log($Message){
        Write-Output (([System.DateTime]::Now).ToString() + " " + $Message)
    }

    function Add-SystemPaths([array] $PathsToAdd) {
        $VerifiedPathsToAdd = ""
        foreach ($Path in $PathsToAdd) {
            if ($Env:Path -like "*$Path*") {
                Log("  Path to $Path already added")
            }
            else {
                $VerifiedPathsToAdd += ";$Path";Log("  Path to $Path needs to be added")
            }
        }
        if ($VerifiedPathsToAdd -ne "") {
            Log("Adding paths: $VerifiedPathsToAdd")
            [System.Environment]::SetEnvironmentVariable("PATH", $Env:Path + "$VerifiedPathsToAdd","Machine")
            Log("Note: Reloading Path env to the current script")
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
    }

    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Log("##########################")
    Log("# Installing VSCode")
    Log("##########################")
    #$url = "https://aka.ms/win32-x64-user-stable"
    #$url = "https://vscode-update.azurewebsites.net/latest/win32-x64-user/stable"
    #$url = "https://go.microsoft.com/fwlink/?Linkid=852157"
    $url = "https://update.code.visualstudio.com/latest/win32-x64/stable"

    Log("Downloading VSCode from $url to VSCodeSetup.exe")
    Invoke-WebRequest -Uri $url -OutFile ($Downloaddir+"\VSCodeSetup.exe")
    Unblock-File ($Downloaddir+"\VSCodeSetup.exe")
    Log("Installing VSCode Using the command: $Downloaddir\VSCodeSetup.exe /verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath")
    $VSCodeInstallResult = (Start-Process ($Downloaddir+"\VSCodeSetup.exe") '/verysilent /suppressmsgboxes /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath,desktopicon,quicklaunchicon' -Wait -Passthru).ExitCode
    if ($VSCodeInstallResult -eq 0) {
        Log("Install VSCode Success")
    }
    Log("Installing VSCode Extensions")
    $VSCodeInstallPath = "C:\Program Files\Microsoft VS Code\bin"
    Set-Location $VSCodeInstallPath
    .\code --install-extension ms-vscode.powershell -force
    .\code --install-extension ms-azuretools.vscode-docker -force
    .\code --install-extension ms-vscode.azurecli -force
    .\code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools -force
    .\code --install-extension ms-vscode-remote.remote-wsl -force
    .\code --install-extension ms-vscode-remote.remote-ssh -force
    Set-Location $Downloaddir
    Log("Cleaning up VSCode Setup")
    Remove-Item .\VSCodeSetup.exe
    Log("Setting up VSCode keybindings for F8 shurtcut")
    $keybindings = '
    // Place your key bindings in this file to override the defaultsauto[]
    [
        {
            "key": "f8",
            "command": "workbench.action.terminal.runSelectedText"
        }
    ]
    '
    $keybindings | Out-File "$env:APPDATA\Code\User\keybindings.json" -Encoding utf8

    Log("#############################")
    Log("#Install Azure CLI")
    Log("#############################")
    Log("Downloading Azure CLI")
    #$ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Log("Installing Azure CLI")
    $AzCLIInstallResult = (Start-Process "msiexec.exe" '/I AzureCLI.msi /quiet' -Wait -Passthru).ExitCode
    if ($AzCLIInstallResult -eq 0) {
        Log("Install Azure CLI Success")
    }
    Log("Cleaning up Azure CLI files")
    Remove-Item .\AzureCLI.msi
    Log("Reload Path")
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Log("#############################")
    Log("#Install WSL2")
    Log("#############################")
    #dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    #dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    Log("Instaling WSL2")
    wsl --install

    Log("#############################")
    Log("#Install Kubectl")
    Log("#############################")
    #Invoke-WebRequest -Uri "https://dl.k8s.io/release/v1.23.0/bin/windows/amd64/kubectl.exe" -OutFile .\kubectl.exe
    Log("Instaling Kubectl using Az CLI - az aks install-cli")
    # az aks install-cli
    $kubectl_latestVersion = Invoke-RestMethod -Uri 'https://storage.googleapis.com/kubernetes-release/release/stable.txt'
    $kubectl_dir = "$env:USERPROFILE\.azure-kubectl"
    if ((Test-Path -Path $kubectl_dir) -ne $true) {
        mkdir $kubectl_dir
    }
    Invoke-WebRequest -Uri "https://storage.googleapis.com/kubernetes-release/release/$kubectl_latestVersion/bin/windows/amd64/kubectl.exe" -OutFile "$kubectl_dir\kubectl.exe"
    Log("Adding Kubectl to PATH")
    Add-SystemPaths $kubectl_dir

    Log("#############################")
    Log("#Install Helm")
    Log("#############################")
    $helm_repo = "helm/helm"
    # https://get.helm.sh/helm-v3.8.1-windows-amd64.zip
    $releases = "https://api.github.com/repos/$helm_repo/releases"
    $tag = (Invoke-WebRequest $releases -UseBasicParsing | ConvertFrom-Json)[0].tag_name
    $helm_file_basename = "helm-$tag-windows-amd64"
    $helm_file =  "$helm_file_basename.zip"
    $download = "https://get.helm.sh/$helm_file"
    Log("Downloading Helm")
    Invoke-WebRequest $download -Out $helm_file
    Log("Extracting Helm")
    Expand-Archive $helm_file -Force
    Log("Moving Helm to right path")
    Move-Item "$helm_file_basename\windows-amd64\helm.exe" "$env:USERPROFILE\.azure-kubectl"
    Log("Cleaning up Helm files")
    Remove-Item $helm_file -Force
    Remove-Item $helm_file_basename -Force -confirm:$false -Recurse

    Log("#############################")
    Log("#Install OC CLI")
    Log("#############################")
    $download = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-windows.zip"
    Log("Downloading OC CLI")
    Invoke-WebRequest $download -Out oc.zip
    Log("Extracting OC CLI")
    Expand-Archive oc.zip -Force
    Log("Moving OC CLI to right path")
    Move-Item .\oc\oc.exe "$env:USERPROFILE\.azure-kubectl"
    Log("Cleaning up OC CLI files")
    Remove-Item oc.zip -Force
    Remove-Item .\oc -Force -confirm:$false -Recurse

    Log("#############################")
    Log("#Install Git")
    Log("#############################")
    # get latest download url for git-for-windows 64-bit exe
    $git_url = "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $asset = Invoke-RestMethod -Method Get -Uri $git_url | ForEach-Object assets | Where-Object name -like "*64-bit.exe"
    $installer = "$($asset.name)"
    Log("Downloading GIT")
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installer
    Log("Installing Git")
    $git_install_args = "/SP- /VERYSILENT /SUPPRESSMSGBOXES /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS"
    $GitInstallResult = (Start-Process ($Downloaddir+"\"+$installer) $git_install_args -Wait -Passthru).ExitCode
    if ($GitInstallResult -eq 0) {
        Log("Install Git Success")
    }
    Log("Cleaning up Git files")
    Remove-Item ($Downloaddir+"\"+$installer) -Force

    Log("#############################")
    Log("#Install Docker Desktop")
    Log("#############################")
    $docker_installer = "Docker_Desktop_Installer.exe"
    $docker_url = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    Log("Downloading Docker Desktop")
    Invoke-WebRequest -Uri $docker_url -OutFile $docker_installer
    Log("Installing Docker Desktop")
    $docker_install_args = "install --quiet --noreboot"
    $DockerInstallResult = (Start-Process ($Downloaddir+"\"+$docker_installer) $docker_install_args -Wait -Passthru).ExitCode
    if ($DockerInstallResult -eq 0) {
        Log("Install Docker Desktop Success")
    }

    Log("#############################")
    Log("#Clean RunOnce Registry")
    Log("#############################")
    Log("Clean RunOnce Registry")
    reg load hklm\temphive C:\Users\Default\NTUSER.DAT
    $RunKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty $RunKey "NextRun"
    reg unload hklm\temphive
    $RunKeyLocal = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    Remove-ItemProperty $RunKeyLocal "NextRun"

    Log("#############################")
    Log("#Reboot")
    Log("#############################")
    Log("Restarting Computer")
    Restart-Computer -Force
    }

    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Creating InstallDir
    $Downloaddir = "C:\InstallDir"
    $scriptblock_fileName = "scriptblock.ps1"
    if ((Test-Path -Path $Downloaddir) -ne $true) {
        mkdir $Downloaddir
    }
    Set-Location $Downloaddir

    $scriptblock | out-file $scriptblock_fileName -Width 4096

    reg load hklm\temphive C:\Users\Default\NTUSER.DAT
    $RunKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    set-itemproperty $RunKey "NextRun" ('C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionPolicy Unrestricted -File ' + "$Downloaddir\$scriptblock_fileName")
    reg unload hklm\temphive
