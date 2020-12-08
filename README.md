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
mkdir install-dir
```
2. Download the script on your system and change the permission to execute.
```
curl https://raw.githubusercontent.com/ocp-power-automation/openshift-install-power/master/openshift-install-powervs -o /usr/bin/openshift-install-powervs
chmod +x /usr/bin/openshift-install-powervs
```
3. Run the script.
```
# openshift-install-powervs

Automation for deploying OpenShift 4.X on PowerVS

Usage:
  openshift-install-powervs [command] [<args> [<value>]]

Available commands:
  setup           Install all required packages/binaries in current directory
  variables       Interactive way to populate the variables file
  create          Create an OpenShift cluster
  destroy         Destroy an OpenShift cluster
  output          Display the cluster information. Runs terraform output [NAME]
  help            Display this information

Where <args>:
  -trace          Enable tracing of all executed commands
  -verbose        Enable verbose for terraform console
  -var            Terraform variable to be passed to the create/destroy command
  -var-file       Terraform variable file name in current directory. (By default using var.tfvars)
  -force-destroy  Not ask for confirmation during destroy command

Submit issues at: https://github.com/ocp-power-automation/openshift-install-power/issues

```

## Pre-requisite

### OpenShift Versions

Before running the script, you may choose to overwrite the environment variables as per your preference. Below given values are default and used when you don’t set them.

If you want to change the OCP version set this variable.
```
export RELEASE_VER="4.6"
```

For using any unreleased OCP version set in `RELEASE_VER` or to use a specific [ocp4-upi-powervs](https://github.com/ocp-power-automation/ocp4-upi-powervs) tag/branch (eg: "v4.5.1", "master") please set the `ARTIFACTS_VERSION`.
```
export ARTIFACTS_VERSION="release-4.6"
```


### Preparing Variables

There are 2 ways you start the deployments.

**1. Bring your own variables file.**

You can pass the variables file using the option`-var-file` to the script. When using own variables file, please ensure the variables values for file system paths are absolute and not relative to the current working directory eg: ` private_key_file = "/home/user/data/id_rsa"`. All the variables provided in the file will take precedence over any environment variables.


**2. Using the variables command.**

The script will automatically run prompts for accepting input variables. You need to set the `CLOUD_API_KEY` environment variable.

### Preparing Files

You need to download the pull-secret.txt file and keep it in the install directory. Ignore if the path is provided in the provided variables file.

Copy the private and public key pairs to the install directory. The file name should match `id_rsa` & `id_rsa.pub`. If not found in the install directory the script will create a new key pair which you can use to login to the cluster nodes.


It can run on multiple x86 platforms including where terraform runs out of the box:


## Platforms

Following are some platform-specific notes you should know. Only 64bit Operating Systems are supported by the script.

### MacOS
The script uses `brew` utility to install required packages for it to run.

### Linux
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
