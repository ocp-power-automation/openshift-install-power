# Command destroy

## What it does

This command when executed will destroy the cluster that was created by the script. You can optionally use other options are listed in the help menu.

Accepts arguments:
```
-verbose  Enable verbose for terraform console
-var      Terraform variable to be passed to the create/destroy command
-var-file Terraform variable file name in current directory. (By default using var.tfvars)
```

Ensure the cluster created using the create command is always destroyed using this script itself before you delete or change the install directory or its contents.

The Terraform console log for each attempt will be stored in `logs/` directory with file name as `ocp4-upi-powervs_<timestamp>_destroy_<attempt_number>.log`. These log files can be used for debugging purpose.

## Usage

```
./openshift-install-powervs destroy
```
