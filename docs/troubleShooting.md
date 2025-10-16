
# OpenShift on IBM PowerVS: Common Issues and Resolutions

This document lists common issues encountered when deploying OpenShift on IBM PowerVS using the `openshift-install-powervs` wrapper, along with their causes and resolutions.

---

## Terraform Stored Resource IDs

**Error:**

Error: cannot find resource with id <resource-id>

**Cause:**  
Terraform retains deleted PowerVS resource IDs in its state or backup files. This often occurs after a Terraform rerun when instances or resources have changed in PowerVS.


**Resolution:**

Search for the stale ID in Terraform state or backup files:

```bash
grep -R "<resource-id>" .
```

Remove stale state entries:

```bash

terraform state rm <resource-name>
```

Re-run the apply:

```bash
terraform apply
```

To rebuild specific worker or master nodes:

```bash
terraform taint module.nodes.ibm_pi_instance.worker[0]
terraform apply
```

## Bastion Node OS Compatibility

If getting errors regarding missing packages or incorrect storage type while using CentOS 10, switch to CentOS Stream 9 to avoid missing package errors or volume type mismatches.

Common Issues and Fixes

Missing Required Packages (e.g. Ansible)

**Error**:
Missing ansible or dependency packages during setup.

**Resolution**:
SSH into the bastion node using the generated key:
ssh -i id_rsa root@<bastion-external-ip>
sudo dnf install ansible

- note: you can also import using python and pip, if the above does not work.

**Error**
Incorrect Storage Type (e.g. "nfs" not recognized)

Error: "pi_volume_type" must contain a value from ["ssd", "standard", "tier1", "tier3"], got ""


**Resolution**:
Edit your variables.tf or corresponding .tfvars file:
bastion_storage_type = "tier3"

- if needed change the defautlt bastion_storage_type in variables.tf to the storage type you desire
- note you can easly find this by hitting CTRL + W and searching for `bastion_storage_type`


## Re-installation / Network Name Conflict

**Error:**

Error: Network with name "ocp-net" already exists.


**Cause:**
On a subsequent UPI install attempt, Terraform tries to create a network with the same name that already exists.
PowerVS does not allow duplicate network names—even if the old network is inactive.

**Resolution:**

- Log into your PowerVS workspace.

- Delete or rename the existing ocp-net network or subnet.

- Re-run the installer:
```bash
    terraform apply ./openshift-install-powervs create
``` 

## Remote-Exec Provisioning Errors

**Error:**

Terraform remote-exec provisioner failures


Cause:
These are transient SSH or remote-execution issues that occur during provisioning.

Resolution:
Re-run Terraform:

terraform apply


This typically resolves the issue automatically.
See ocp4-upi-powervs known issues for more details. ["OCP Known issues"]((https://github.com/ocp-power-automation/ocp4-upi-powervs/blob/release-4.6/docs/known_issues.md))

5. LPAR in WARNING State

Error:

Error: the operation cannot be performed when the lpar health in the WARNING State


Cause:
Terraform cannot modify instances whose PowerVS LPAR health is in WARNING state.
This often occurs after partial provisioning, failed networking setup, or API timeouts.

Resolution:

Check instance health:
```bash
ibmcloud pi instance get <INSTANCE_ID>
```
**Note**: Due to RSCT daemon not being available for RHCOS, RHCOS instances in dashboard can show "Warning" Status, ignore this!

In console reboot instances by OS shutting down the instance, then restarting

To rebuild only specific nodes:
```bash

terraform taint module.nodes.ibm_pi_instance.master[1]
terraform taint module.nodes.ibm_pi_instance.worker[0]
terraform apply
```

## Missing or Outdated Images (RHEL / RHCOS)

**Error:**

Error: failed to perform Get Image Operation for image rhcos-4.15
[pcloudCloudinstancesImagesGetNotFound] image does not exist. ID: rhcos-4.12

**Cause:**
Terraform and the PowerVS provider reference image names (e.g. rhcos-4.15, rhel-8.3) that may not exist in your workspace.
The wrapper may also use the RHEL version for RHCOS images by mistake.

**Resolution:**

Option 1 — Import Pre-built Images

Use pre-built RHCOS and RHEL OVA images from IBM’s public repository.
See Christy Norman’s blog
 for steps. ["Blog"](https://community.ibm.com/community/user/blogs/christy-norman/2024/08/06/import-pre-built-red-hat-coreos-ovas-into-powervs)

Option 2 — Update variables.tf

Set available image names manually:
```bash

variable "rhel_image_name" {
  default = "rhel-9.6"
}

variable "rhcos_image_name" {
  default = "rhcos-4.19"
}
```
Option 3 — Export Versions Before Running
export RELEASE_VER=4.9

Ensure RHEL and RHCOS versions are aligned and available.