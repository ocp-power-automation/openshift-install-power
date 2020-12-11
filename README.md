# OpenShift 4 on PowerVS Automation

- [Introduction](#introduction)
- [Features](#features)
- [Usage](#usage)
- [Pre-requisite](#pre-requisite)
  - [OpenShift Versions](#openShift-versions)
  - [Preparing Variables](#preparing-variables)
  - [Preparing Files](#preparing-files)
- [Platforms](#usage)
  - [MacOS](#macos)
  - [Linux](#linux)
  - [Windows](#windows)
- [Commands Explained](#commands-explained)
  - [setup](#setup)
  - [variables](#variables)
  - [create](#create)
  - [destroy](#destroy)
- [Quickstart](#quickstart)

## Introduction

This project contains a script that can help you deploy OpenShift Container Platform 4.X on [IBM® Power Systems™ Virtual Server on IBM Cloud](https://www.ibm.com/cloud/power-virtual-server) (Power VS). The Terraform code at [ocp4-upi-powervs](https://github.com/ocp-power-automation/ocp4-upi-powervs/) is used for the deployment process.

## Features

* Supports multiple x86 platforms (64bits) including Linux, Windows & Mac OSX
* Setup the latest IBM Cloud CLI with Power Virtual Servers plugin.
* Setup the latest Terraform
* Populate Terraform variables required for the automation
* Abstract out the Terraform lifecycle management
* Manage deployment of OpenShift (4.5 onwards) cluster on Power VS

## Usage

1. Create an install directory where all the configurations, logs and data files will be stored.
```
# mkdir ocp-install-dir
```
2. Download the script on your system and change the permission to execute.
```
# curl https://raw.githubusercontent.com/ocp-power-automation/openshift-install-power/master/openshift-install-powervs -o ./openshift-install-powervs
# chmod +x ./openshift-install-powervs
```
3. Run the script.
```
# ./openshift-install-powervs

Automation for deploying OpenShift 4.X on PowerVS

Usage:
  openshift-install-powervs [command] [<args> [<value>]]

Available commands:
  setup           Install all the required packages/binaries in current directory
  variables       Interactive way to populate the variables file
  create          Create an OpenShift cluster
  destroy         Destroy an OpenShift cluster
  output          Display the cluster information. Runs terraform output [NAME]
  access-info     Display the access information of installed OpenShift cluster
  help            Display this information

Where <args>:
  -var            Terraform variable to be passed to the create/destroy command
  -var-file       Terraform variable file name in current directory. (By default using var.tfvars)
  -force-destroy  Not ask for confirmation during destroy command
  -verbose        Enable verbose for terraform console messages
  -all-images     List all the images available during variables prompt
  -trace          Enable tracing of all executed commands
  -version, -v    Display the script version

Environment Variables:
  IBMCLOUD_API_KEY    IBM Cloud API key
  RELEASE_VER         OpenShift release version (Default: 4.6)
  ARTIFACTS_VERSION   Tag or Branch name of ocp4-upi-powervs repository (Default: release-<RELEASE_VER>)
  RHEL_SUBS_PASSWORD  RHEL subscription password if not provided in variables
  NO_OF_RETRY         Number of retries/attemps to run repeatable actions such as create (Default: 5)

Submit issues at: https://github.com/ocp-power-automation/openshift-install-power/issues

```

## Pre-requisite

### OpenShift Versions

Before running the script, you may choose to overwrite some environment variables as per your preference.

RELEASE_VER: OCP version you need to install. Default is 4.6.
```
# export RELEASE_VER="4.6"
```

ARTIFACTS_VERSION: Tag/Branch (eg: release-4.6, v4.5.1, master) of [ocp4-upi-powervs](https://github.com/ocp-power-automation/ocp4-upi-powervs) repository. Default is "release-<RELEASE_VER>".
```
# export ARTIFACTS_VERSION="release-4.6"
```


### Preparing Variables

There are 2 ways you start the deployments.

**1. Bring your own variables file.**

You can pass the variables file using the option `-var-file <filename>` to the script. You can also use the option `-var "key=value"` to pass a single variable. If the same variable is given more than once then precedence will be from left (low) to right (high).

- Please ensure the variables values for file system paths are absolute and not relative to the current working directory eg: ` private_key_file = "/home/user/data/id_rsa"`.
- You could also use environment variables for setting sensitive variables eg: IBMCLOUD_API_KEY, RHEL_SUBS_PASSWORD.
- All the variables provided will take precedence over any environment variables.


**2. Using the variables command.**

The script will automatically run prompts for accepting input variables.

You need to set the `IBMCLOUD_API_KEY` environment variable. Please refer to the link for the instructions to generate the API key - https://cloud.ibm.com/docs/account?topic=account-userapikey
```
# export IBMCLOUD_API_KEY="<your API key>"
```


### Preparing Files

**Pull-secret file**
You need to download the pull-secret.txt file and keep it in the install directory. Download is available from the following link - https://cloud.redhat.com/openshift/install/power/user-provisioned. Ignore this if the path is provided in the variables.

**SSH Key files**
Copy the private and public key pairs to the install directory. The file name should match `id_rsa` & `id_rsa.pub`. If not found in the install directory the script will create a new key pair which you can use to login to the cluster nodes.


## Platforms

Following are some platform-specific notes you should know. Only 64bit Operating Systems are supported by the script.

### MacOS
The script uses `brew` utility to install required packages for it to run.

### Linux (x86)
The script is tested to use on Ubuntu and other Debian platforms where `apt-get` is available.
For Fedora the script use `dnf` and for RHEL/CentOS the script use `yum` commands to install the required packages.

### Windows

The script can run on GitBash and Cygwin terminals. We have also tested it on Windows Subsystem for Linux using Ubuntu.

Please ensure `curl` and `unzip` packages are installed on Cygwin. You might need to run the Cygwin setup again.

Please note that running from **PowerShell is NOT SUPPORTED**.


## Commands Explained

The following core commands are supported by the script.

### [setup](docs/setup.md)
### [variables](docs/variables.md)
### [create](docs/create.md)
### [destroy](docs/destroy.md)

Below is a simple flow chart explaining the flow of each command.

![Flow Chart](./docs/images/flow_chart.jpg)

## Quickstart

For quickstart just run the `create` command.
```
# ./openshift-install-powervs create
```

The above command will setup the required tools, run prompts for accepting input variables and create a cluster. Please try running the command again if it gives errors related to the network or infrastructure.

Once the above command runs successfully it will print the cluster access information. You can get this information anytime using below command.
```
# ./openshift-install-powervs access-info
Login to bastion: 'ssh -i automation/data/id_rsa root@145.48.43.53' and start using the 'oc' command.
To access the cluster on local system when using 'oc' run: 'export KUBECONFIG=/root/ocp-install-dir/automation/kubeconfig'
Access the OpenShift web-console here: https://console-openshift-console.apps.test-ocp-6f2c.ibm.com
Login to the console with user: "kubeadmin", and password: "MHvmI-z5nY8-CBFKF-hmCDJ"
Add the line on local system 'hosts' file:
145.48.43.53 api.test-ocp-6f2c.ibm.com console-openshift-console.apps.test-ocp-6f2c.ibm.com integrated-oauth-server-openshift-authentication.apps.test-ocp-6f2c.ibm.com oauth-openshift.apps.test-ocp-6f2c.ibm.com prometheus-k8s-openshift-monitoring.apps.test-ocp-6f2c.ibm.com grafana-openshift-monitoring.apps.test-ocp-6f2c.ibm.com example.apps.test-ocp-6f2c.ibm.com

```
