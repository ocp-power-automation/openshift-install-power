# OpenShift 4 on PowerVS Automation

This repo contain a bash script which can help you deploy OpenShift Container Platform 4.X on [IBM® Power Systems™ Virtual Server on IBM Cloud](https://www.ibm.com/cloud/power-virtual-server).

The script make use of Terraform configurations from [ocp4-upi-powervs](https://github.com/ocp-power-automation/ocp4-upi-powervs/). Do check out the [README](https://github.com/ocp-power-automation/ocp4-upi-powervs/blob/master/README.md).

## What can the script do

It can run on multiple x86 platforms including where terraform runs out of the box:

- Mac OSX (Darwin)
- Linux (x86_64)
- Windows 10 (Git Bash & Cygwin)

It can setup the latest IBM Cloud CLI and Terraform for you.

It can help you populate variables for [ocp4-upi-powervs](https://github.com/ocp-power-automation/ocp4-upi-powervs/) via interactive prompts.

It can help you create an OpenShift cluster for you on PowerVS. Thanks to the project [ocp4-upi-powervs](https://github.com/ocp-power-automation/ocp4-upi-powervs/).

## How to use

Just create an install directory and download the script on the box.

`curl https://raw.githubusercontent.com/ocp-power-automation/powervs_automation/master/deploy.sh -o deploy.sh && chmod +x deploy.sh`

You are good to run the script:

```
# ./deploy.sh

Automation for deploying OpenShift 4.X on PowerVS

Usage:
  ./deploy.sh [command] [<args> [<value>]]

Available commands:
  setup       Install all required packages/binaries in current directory
  variables   Interactive way to populate the variables file
  create      Create an OpenShift cluster
  destroy     Destroy an OpenShift cluster
  output      Display the cluster information. Runs terraform output [NAME]
  help        Display this information

Where <args>:
  -trace      Enable tracing of all executed commands
  -verbose    Enable verbose for terraform console
  -var        Terraform variable to be passed to the create/destroy command
  -var-file   Terraform variable file name in current directory. (By default using var.tfvars)

Submit issues at: https://github.com/ocp-power-automation/ocp4-upi-powervs/issues

```
