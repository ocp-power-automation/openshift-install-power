# Command create

## What it does

This command when executed will start off the deployment process. You can optionally use other options are listed in the help menu.

Accepts arguments:

```
  -verbose        Enable verbose for terraform console
  -var            Terraform variable to be passed to the create/destroy command
  -var-file       Terraform variable file name in current directory. (By default using var.tfvars)
```

The `create` command will check if all the tools are installed for the deployment to start. If not then it will run the [setup](setup.md) command. Next, it will check if the variables file var.tfvars is available in the install directory or provided via argument `-var-file`, if not then it will run the [variables](variables.md) command.

The Terraform console log for each attempt will be stored in `logs/` directory with file name as `ocp4-upi-powervs_<timestamp>_apply_<attempt_number>.log`. These log files can be used for debugging purpose.

## Usage

When `setup` and/or `variables` command are already completed.

```
# openshift-install-powervs create
[setup_tools] Verifying the latest packages and tools
[precheck] Trying to login with the provided IBMCLOUD_API_KEY...
Targeting service crn:v1:bluemix:public:power-iaas:tor01:a/65b64c1f1c29XXXXXXXXXc:4a7700b1-e318-476b-9bf6-5a88XXXXXXX981::...
[init_terraform] Initializing Terraform plugins...
[init_terraform] Validating Terraform code...
[apply] Running terraform apply... please wait
Attempt: 1/3
[retry_terraform] Completed running the terraform command.
Login to bastion: 'ssh -i automation/data/id_rsa root@169.48.X.X' and start using the 'oc' command.
To access the cluster on local system when using 'oc' run: 'export KUBECONFIG=/root/ocp-power-automation/openshift-install-power/automation/kubeconfig'
Access the OpenShift web-console here: https://console-openshift-console.apps.mycluster-cf34.ibm.com
Login to the console with user: "kubeadmin", and password: "SBPpp-CUZXV-jhyL6-ZfxRX"
Add the line on local system 'hosts' file:
169.48.X.X api.mycluster-cf34.ibm.com console-openshift-console.apps.mycluster-cf34.ibm.com integrated-oauth-server-openshift-authentication.apps.mycluster-cf34.ibm.com oauth-openshift.apps.mycluster-cf34.ibm.com prometheus-k8s-openshift-monitoring.apps.mycluster-cf34.ibm.com grafana-openshift-monitoring.apps.mycluster-cf34.ibm.com example.apps.mycluster-cf34.ibm.com
[cluster_access_info] SUCCESS: Congratulations! create command completed

```
