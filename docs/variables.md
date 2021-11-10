# Command variables

## What it does

This command when executed will run interactive prompts for gathering inputs for installing OpenShift on PowerVS. The results will be stored in a file named `var.tfvars` in the current directory which will be used as an input to the Terraform automation.

The installation process needs `pull-secret.txt` in the current directory for downloading OpenShift images on the cluster. If not found, the variables command will prompt for pull-secret contents.

Similar to pull-secret.txt file the script will also lookup for `id_rsa` & `id_rsa.pub` files in the current directory. If not found it will prompt to use the current login user's SSH key pair at `~/.ssh/`. If you reply a `no` then the script will create an SSH key pair for you in the current directory. The private key `id_rsa` can be used to login to the cluster. The SSH keys should be in OpenSSH format and without a passphrase.

Please ensure you have exported the IBM Cloud API key using following command:
```
export IBMCLOUD_API_KEY=<your api key>
```

Optionally you could also export the RHEL subscription password if you do not want to store it in the variables file. 
```
export RHEL_SUBS_PASSWORD='<your subscription password>'
```

The script will try to filter the images for selection. The argument `-all-images` can be used to display all the available images during the prompt for RHEL and RHCOS image.

**There will be series of questions mainly categorized as:**

### Multi choice question
List of options will be displayed where you need to enter the number corresponding to the choice you want to select.
```
[question] > Select the RHEL image to use for bastion node:
1) rhel-82-10162020
2) rhel-83-11032020
#? 1
- You have answered: rhel-82-10162020
```

### Question with default value
The question will have a default value present at the end in (round-brackets). Just press enter if you want to use the default value OR type the value you want and press Enter key.
```
[question] > Enter a short name to identify the cluster (test-ocp)
?
- You have answered: test-ocp
[question] > Enter a domain name for the cluster (ibm.com)
? myorg.com
- You have answered: myorg.com

```

### Question in plain text
The question which can be answered in plain text. Enter the value you want and press Enter key.
```
[question] > Enter RHEL subscription username for bastion nodes
? myredhatuser
- You have answered: myredhatuser
```

### Question with sensitive value
The question which accept sensitive information such as passwords and pull-secret contents.
```
[question] > Enter the password for above username. WARNING: If you do not wish to store the subscription password please export RHEL_SUBS_PASSWORD
- ***********
```


## Usage

```
# ./openshift-install-powervs variables
[setup_tools] Verifying the latest packages and tools
[variables] Trying to login with the provided IBMCLOUD_API_KEY...
[question] > Select the Service Instance name to use:
1) ocp-cicd-toronto-01
2) ocp-internal-toronto
#? 1
- You have answered: ocp-cicd-toronto-01
Targeting service crn:v1:bluemix:public:power-iaas:tor01:a/65b64c1f1c2XXXXX:4a1f10a2-0797-4ac8-9c41-XXXXXXX::...
[variables] Gathering information from the selected Service Instance... Please wait
[question] > Select the RHEL image to use for bastion node:
1) rhel-82-10162020
2) rhel-83-11032020
#? 1
- You have answered: rhel-82-10162020
[question] > Select the RHCOS image to use for cluster nodes:
1) rhcos-45-09242020
2) rhcos-46-09182020
3) rhcos-47-10172020
#? 2
- You have answered: rhcos-46-09182020
[question] > Select the private network to use:
1) ocp-net
#? 1
- You have answered: ocp-net
[question] > Select the system type to use for cluster nodes:
1) e980
2) s922
#? 2
- You have answered: s922
[question] > Select the OCP version to use:
1) 4.5.4            4) 4.5.7           7) 4.5.10         10) 4.5.13         13) 4.5.16         16) 4.5.19         19) fast-4.5
2) 4.5.5            5) 4.5.8           8) 4.5.11         11) 4.5.14         14) 4.5.17         17) 4.5.20         20) latest-4.5
3) 4.5.6            6) 4.5.9           9) 4.5.12         12) 4.5.15         15) 4.5.18         18) candidate-4.5  21) stable-4.5
#? 11
- You have answered: 4.5.14
[question] > Enter a short name to identify the cluster (test-ocp)
?
- You have answered: test-ocp
[question] > Enter a domain name for the cluster (ibm.com)
? myorg.com
- You have answered: myorg.com
[question] > Do you want to configure High Availability for bastion nodes?
1) yes
2) no
#? 2
- You have answered: no
[question] > Do you need NFS storage to be configured?
1) yes
2) no
#? 1
- You have answered: yes
[question] > Enter the NFS volume size(GB) (300)
?
- You have answered: 300
[question] > Select the flavor for the cluster nodes:
1) large
2) medium
3) small
4) CUSTOM
#? 4
- You have answered: CUSTOM
[question] > Do you want to use the default configuration for all the cluster nodes?
1) yes
2) no
#? 1
- You have answered: yes
[question] > Enter RHEL subscription username for bastion nodes
? myredhatuser
- You have answered: myredhatuser
[question] > Enter the password for above username. WARNING: If you do not wish to store the subscription password please export RHEL_SUBS_PASSWORD

[question] > Enter the pull-secret
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
***************************************
[question] > Found SSH key pair in /root/.ssh/ do you want to use them? (yes)

?
- You have answered: yes
[question] > Do you want to use IBM Cloud Classic DNS and VPC Load Balancer services?
1) yes
2) no
#? 1
- You have answered: yes
[question] > Enter IBM Cloud VPC name
? ocp-vpc-fra
- You have answered: ocp-vpc-fra
[question] > Enter IBM Cloud VPC subnet name
? ocp-subnet
- You have answered: ocp-subnet
[question] > Enter IBM Cloud VPC Infrastructure region. (Power VS region will be used for VPC if you do not provide any value).
? us-south
- You have answered: us-south
[variables] SUCCESS: variables command completed!
```

### Using with flavor argument
It skips all flavor related questions.

```
# ./openshift-install-powervs variables -flavor small
[setup_tools] Verifying the latest packages and tools
[variables] Trying to login with the provided IBMCLOUD_API_KEY...
[question] > Select the Service Instance name to use:
1) ocp-cicd-toronto-01
2) ocp-internal-toronto
#? 1
- You have answered: ocp-cicd-toronto-01
Targeting service crn:v1:bluemix:public:power-iaas:tor01:a/65b64c1f1c2XXXXX:4a1f10a2-0797-4ac8-9c41-XXXXXXX::...
[variables] Gathering information from the selected Service Instance... Please wait
[question] > Select the RHEL image to use for bastion node:
1) rhel-82-10162020
2) rhel-83-11032020
#? 1
- You have answered: rhel-82-10162020
[question] > Select the RHCOS image to use for cluster nodes:
1) rhcos-45-09242020
2) rhcos-46-09182020
3) rhcos-47-10172020
#? 2
- You have answered: rhcos-46-09182020
[question] > Select the private network to use:
1) ocp-net
#? 1
- You have answered: ocp-net
[question] > Select the OCP version to use:
1) 4.5.4            4) 4.5.7           7) 4.5.10         10) 4.5.13         13) 4.5.16         16) 4.5.19         19) fast-4.5
2) 4.5.5            5) 4.5.8           8) 4.5.11         11) 4.5.14         14) 4.5.17         17) 4.5.20         20) latest-4.5
3) 4.5.6            6) 4.5.9           9) 4.5.12         12) 4.5.15         15) 4.5.18         18) candidate-4.5  21) stable-4.5
#? 11
- You have answered: 4.5.14
[question] > Enter a short name to identify the cluster (test-ocp)
?
- You have answered: test-ocp
[question] > Enter a domain name for the cluster (ibm.com)
? myorg.com
- You have answered: myorg.com
[question] > Do you want to configure High Availability for bastion nodes?
1) yes
2) no
#? 2
- You have answered: no
[question] > Do you need NFS storage to be configured?
1) yes
2) no
#? 2
- You have answered: no
[question] > Enter RHEL subscription username for bastion nodes
? myredhatuser
- You have answered: myredhatuser
[question] > Enter the password for above username. WARNING: If you do not wish to store the subscription password please export RHEL_SUBS_PASSWORD

[question] > Enter the pull-secret
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
********************************************************************************************************************************
***************************************
[question] > Found SSH key pair in /root/.ssh/ do you want to use them? (yes)

?
- You have answered: yes
[question] > Do you want to use IBM Cloud Classic DNS and VPC Load Balancer services?
1) yes
2) no
#? 1
- You have answered: yes
[question] > Enter IBM Cloud VPC name
? ocp-vpc-fra
- You have answered: ocp-vpc-fra
[question] > Enter IBM Cloud VPC subnet name
? ocp-subnet
- You have answered: ocp-subnet
[question] > Enter IBM Cloud VPC Infrastructure region. (Power VS region will be used for VPC if you do not provide any value).
? us-south
- You have answered: us-south
[variables] SUCCESS: variables command completed!
```
