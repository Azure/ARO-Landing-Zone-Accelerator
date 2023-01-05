# ARO Landing Zone

This Ansible deployment bundle contains everything needed to stand up an Azure Red Hat OpenShift cluster in an Azure Landing Zone.

It's currently stand alone while in development but is modeled to match the architectures found in the [Azure ARO Landing Zone Accelerator](https://github.com/Azure/ARO-Landing-Zone-Accelerator).

## Requirements

Ansible and Python requirements are captured in `./requirements.txt` on a Linux or OSX system you can run `make virtualenv` to deploy Ansible and its dependencies in `./virtualenv` and then active it.

If you have a Windows machine it is recommended that you use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) to run a linux subsystem and run these commands from there.

## Variables and Configuration

There are a large number of variables that can be set to deploy this project, however the more common ones are captured in the inventory file `environment/private/group_vars/all.yml`

## Using

* Create a Python virtualenv and install Ansible

```
make virtualenv
```

* Deploy ARO Landing Zone

```bash
make create
```

### Accessing the cluster

If you deployed a private cluster using the above `make create` command there are two ways to access your cluster. One is through the Linux jumphost which has a public IP, The other is through the Windows jumphost which can be accessed via a Bastion connection in your Azure Portal.

The username for both is `aro` and you can find the password in the `jumpbox-password` secret that is created in the Key Vault named `lz-hub-aro-kv`.

You can run OC commands to log into the cluster from either. You can also use `sshuttle` and similar tools to tunnel your local connection through the linux jumphost.

## Cleanup

```bash
make destroy
```

## License

Copyright 2022 Red Hat, Microsoft

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
