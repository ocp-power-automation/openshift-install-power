# Command create

## What it does

This command when executed will start off the deployment process. You can optionally use other options are listed in the help menu.

Accepts arguments:
```
-verbose  Enable verbose for terraform console
-var      Terraform variable to be passed to the create/destroy command
-var-file Terraform variable file name in current directory. (By default using var.tfvars)
```

The create command will check if all the tools are installed for the deployment to start. If not then it will run the [setup](setup.md) command. Next, it will check if the variables file var.tfvars is available in the install directory or provided via argument `-var-file`, if not then it will run the [variables](variables.md) command.

The Terraform console log for each attempt will be stored in `logs/` directory with file name as `ocp4-upi-powervs_<timestamp>_apply_<attempt_number>.log`. These log files can be used for debugging purpose.

## Usage

```
./openshift-install-powervs create
```
