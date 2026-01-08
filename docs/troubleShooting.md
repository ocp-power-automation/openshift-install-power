
# Common Issues and Resolutions

The following lists common issues encountered when deploying OpenShift on IBM PowerVS using the `openshift-install-powervs` wrapper, along with their causes and resolutions.



## 1.  Re-installation / Network Name Conflict

**Error**

"Network with name "ocp-net" already exists."


**Cause**

On a subsequent UPI install attempt, Terraform tries to create a network with the same name that already exists.
PowerVS does not allow duplicate network names—even if the old network is inactive.

**Resolution**

- Log into your PowerVS workspace.
- Delete or rename the existing ocp-net network or subnet.
- Re-run the installer:
```bash
  ./openshift-install-powervs create
``` 

## 2. Remote-Exec Provisioning Errors

**Error**

"Terraform remote-exec provisioner failures"


**Cause**

These are transient SSH or remote-execution issues that occur during provisioning.

**Resolution**

Re-run the installer using the wrapper command:
```bash
 ./openshift-install-powervs create
 ```


This will re-attempt the provisioning steps and typically resolves transient remote-exec issues.
See ocp4-upi-powervs known issues for more details: ["OCP Known issues"](https://github.com/ocp-power-automation/ocp4-upi-powervs/blob/main/docs/known_issues.md)


## 3. Missing or Outdated Images (RHEL / RHCOS)

**Error**

"failed to perform Get Image Operation for image rhcos-4.20
[pcloudCloudinstancesImagesGetNotFound] Image does not exist. ID: rhcos-4.20"

**Cause**

Terraform and the PowerVS provider reference image names (e.g. rhcos-4.20, rhel-9.63) that may not exist in your workspace.
The wrapper may also use the RHEL version for RHCOS images by mistake.

**Resolution**

*Option 1* — Import Pre-built Images

Use pre-built RHCOS and RHEL OVA images from IBM’s public repository.
See Christy Norman’s blog
 for steps. ["Pre-built Images Blog"](https://community.ibm.com/community/user/blogs/christy-norman/2024/08/06/import-pre-built-red-hat-coreos-ovas-into-powervs)

*Option 2* — Update variables.tf

Set available image names manually:
```bash
variable "rhel_image_name" {
  default = "rhel-9.6"
}

variable "rhcos_image_name" {
  default = "rhcos-4.20"
}
```
*Option 3* — Export Versions Before Running
export RELEASE_VER=4.20

Ensure that the RHEL and RHCOS versions are aligned and available in your workspace.



### **Developers Only**

>  ⚠️ WARNING: The following command is intended **for developers or advanced users only**.
>  
> Using this command without a full understanding of its purpose and impact can lead to an **inconsistent Terraform state**, **resource corruption**, or **loss of data**.  
>
> Proceed **only if you understand** how Terraform manages state and resource dependencies.  
> Always create a state backup before making manual modifications.

## 4. LPAR in WARNING State

**Error**

"The operation cannot be performed when the lpar health in the WARNING State."


**Cause**

Terraform cannot modify instances whose PowerVS LPAR health is in WARNING state.
This often occurs after partial provisioning, failed networking setup, or API timeouts.

**Resolution**

Check instance health:
```bash
ibmcloud pi instance get <INSTANCE_ID>
```
**Note**: Due to RSCT daemon not being available for RHCOS, RHCOS instances in dashboard can show "Warning" Status, you can safely ignore this.

In the console, reboot instances by OS shutting them down and restarting them

To rebuild only specific nodes:
```bash
terraform taint module.nodes.ibm_pi_instance.master[1]
terraform taint module.nodes.ibm_pi_instance.worker[0]
terraform apply
```


## 5. Terraform Stored Resource IDs

**Error**

"cannot find resource with id `<resource-id>`"

**Cause** 

Terraform retains deleted PowerVS resource IDs in its state or backup files. This often occurs after a Terraform rerun when instances or resources have changed in PowerVS.


**Resolution**

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
