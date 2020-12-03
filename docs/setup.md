# Command setup

## What it does

This command when executed will setup the automation requirements to be run in the current directory. It will setup required system packages, IBM Cloud CLI and power-iaas plugin, Terraform and the automation code (artifacts).

### Install system packages
Installs all the required packages/binaries in current directory. The script will install following packages using the package manager installed on your system. 
1. curl
1. unzip

Note: This is not applicable for Windows OS, make sure the commands are available before running the script.

### Setup IBM Cloud CLI

Downloads the latest IBM Cloud CLI binary. The downloaded binary is placed in the current directory.

If the latest CLI is already present in the system PATH then the script will create a symbolic link in the current directory and use it. The script does not download the binary in this case.

### Setup IBM Cloud plug-in for Power (power-iaas)

Installs the latest IBM Cloud power-iaas plug-in if the latest is not installed already.

### Setup Terraform

Downloads the latest Terraform binary from https://releases.hashicorp.com/terraform/. The downloaded binary is placed in the current directory.

If the latest Terraform is already present in the system PATH then the script will create a symbolic link in the current directory and use it. The script does not download the binary in this case.

### Download the artifacts

Downloads the Terraform artifacts which is used to create the OpenShift 4 cluster on PowerVS at IBM Cloud.

The script uses environment variable ARTIFACTS_VERSION to download the [OCP on PowerVS](https://github.com/ocp-power-automation/ocp4-upi-powervs) code. ARTIFACTS_VERSION can set to the branch or tag name eg: release-4.5 _(default)_, release-4.6, v4.5.1, etc.

Another environment variable you can set is OCP_RELEASE to the OpenShift version you want to install. eg: 4.5, 4.6, etc.


## Usage

When you run the `setup` command first time in a clean directory:
```
# ./deploy.sh setup
[setup] Installing dependency packages
[setup_ibmcloudcli] IBM-Cloud CLI latest version already installed on the system
./ibmcloud version 1.2.3+3577aee6-2020-09-25T14:34:09+00:00
[setup_poweriaas] Plugin power-iaas already installed
[setup_terraform] Terraform latest version already installed on the system
Terraform v0.13.5
[setup_artifacts] Downloading code artifacts release-4.5 in ./automation
Attempt: 1/2
[setup] SUCCESS: setup command completed!

```

When you run the `setup` command again it will display "already installed" messages. It will delete the existing code artifacts and download it again using the value of environment variable ARTIFACTS_VERSION.

```
# ./deploy.sh setup
[setup] Installing dependency packages
[setup_ibmcloudcli] IBM-Cloud CLI latest version already installed
./ibmcloud version 1.2.3+3577aee6-2020-09-25T14:34:09+00:00
[setup_poweriaas] Plugin power-iaas already installed
[setup_terraform] Terraform latest version already installed
Terraform v0.13.5
[setup_artifacts] Downloading code artifacts release-4.5 in ./automation
Attempt: 1/2
[setup] SUCCESS: setup command completed!
```
