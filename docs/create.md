# Command create

## What it does

This command when executed will start off the deployment process. You can optionally use other options are listed in the help menu.

Accepts arguments:

```
  -verbose        Enable verbose for terraform console
  -var            Terraform variable to be passed to the create/destroy command
  -var-file       Terraform variable file name in current directory. (By default using var.tfvars)
  -flavor         Cluster compute template to use eg: small, medium, large
```

The `create` command will check if all the tools are installed for the deployment to start. If not then it will run the [setup](setup.md) command. Next, it will check if the variables file var.tfvars is available in the install directory or provided via argument `-var-file`, if not then it will run the [variables](variables.md) command.

The compute template can also be changed in the var.tfvars file using the `-flavor` argument via command `# ./openshift-install-powervs create -flavor small`. The [flavors](flavor.md) refer to the templates from https://github.com/ocp-power-automation/ocp4-upi-powervs/tree/main/compute-vars.

The Terraform console log for each attempt will be stored in `logs/` directory with file name as `ocp4-upi-powervs_<timestamp>_apply_<attempt_number>.log`. These log files can be used for debugging purpose.

## Usage

When `setup` and/or `variables` commands are already completed.

```
# openshift-install-powervs create
[setup_tools] Verifying the latest packages and tools
[powervs_login] Trying to login with the provided IBMCLOUD_API_KEY...
Targeting service crn:v1:bluemix:public:power-iaas:tor01:a/65b64c1f1c29XXXXXXXXXc:4a7700b1-e318-476b-9bf6-5a88XXXXXXX981::...
[init_terraform] Initializing Terraform plugins...
[init_terraform] Validating Terraform code...
[apply] Running terraform apply... please wait
Attempt: 1/5
[retry_terraform] Completed running the terraform command.
Login to bastion: 'ssh -i automation/data/id_rsa root@145.48.43.53' and start using the 'oc' command.
To access the cluster on local system when using 'oc' run: 'export KUBECONFIG=/root/ocp-install-dir/automation/kubeconfig'
Access the OpenShift web-console here: https://console-openshift-console.apps.test-ocp-6f2c.ibm.com
Login to the console with user: "kubeadmin", and password: "MHvmI-z5nY8-CBFKF-hmCDJ"
Add the line on local system 'hosts' file:
145.48.43.53 api.test-ocp-6f2c.ibm.com console-openshift-console.apps.test-ocp-6f2c.ibm.com integrated-oauth-server-openshift-authentication.apps.test-ocp-6f2c.ibm.com oauth-openshift.apps.test-ocp-6f2c.ibm.com prometheus-k8s-openshift-monitoring.apps.test-ocp-6f2c.ibm.com grafana-openshift-monitoring.apps.test-ocp-6f2c.ibm.com example.apps.test-ocp-6f2c.ibm.com
[cluster_access_info] SUCCESS: Congratulations! create command completed

```
