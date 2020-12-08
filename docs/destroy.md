# Command destroy

## What it does

This command when executed will destroy the cluster that was created by the script. You can optionally use other options are listed in the help menu.

Accepts arguments:

```
  -verbose        Enable verbose for terraform console
  -var            Terraform variable to be passed to the create/destroy command
  -var-file       Terraform variable file name in current directory. (By default using var.tfvars)
  -force-destroy  Not ask for confirmation during destroy command
```

Ensure the cluster created using the `create` command is always destroyed using this script itself before you delete or change the install directory or its contents. Also make use of the same variables you had used for `create` command.

The Terraform console log for each attempt will be stored in `logs/` directory with file name as `ocp4-upi-powervs_<timestamp>_destroy_<attempt_number>.log`. These log files can be used for debugging purpose.

## Usage

When the response is 'no' or any other input during the confirmation.

```
# openshift-install-powervs destroy
[question] > Are you sure you want to proceed with destroy? (yes)
? no
- You have answered: no
[destroy] SUCCESS: Exiting on user request

```

When using `-force-destroy` option.

```
# openshift-install-powervs destroy -force-destroy
[main] WARN: Enabling forceful destruction option for terraform destroy command
[setup_tools] Verifying the latest packages and tools
[precheck] Trying to login with the provided CLOUD_API_KEY...
Targeting service crn:v1:bluemix:public:power-iaas:tor01:a/65b64c1f1c29460e8c2e4bbfbd893c2c:4a7700b1-e318-476b-9bf6-5a88d840f981::...
[destroy] Running terraform destroy... please wait
Attempt: 1/2
[retry_terraform] Completed running the terraform command.
[destroy] SUCCESS: Done! destroy commmand completed

```
