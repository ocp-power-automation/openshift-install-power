ibmcloud_region = "dal"
ibmcloud_zone = "dal14"
service_instance_id = "workspace-id"
rhel_image_name =  "RHEL9-SP6"
rhcos_image_name =  "rhcos-9-6-20260619-0-ppc64le"
system_type =  "s1122"
network_name =  "ocp-bgp-subnet"
openshift_install_tarball =  "https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp/latest-4.20/openshift-install-linux.tar.gz"
openshift_client_tarball =  "https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp/latest-4.20/openshift-client-linux.tar.gz"
cluster_id_prefix = "test-ocp"
cluster_domain = "ocptest.xyz"
## Medium Configuration Template

bastion   = { memory = "16", processors = "1", "count" = 1 }
bootstrap = { memory = "32", processors = "0.5", "count" = 1 }
master    = { memory = "32", processors = "0.5", "count" = 3 }
worker    = { memory = "32", processors = "0.5", "count" = 3 }

storage_type = "none"
rhel_subscription_username = "mgomezmx2"
rhel_subscription_password = ""
pull_secret_file = "/root/ocp-install-dir2/pull-secret.txt"
private_key_file = "/root/ocp-install-dir2/id_rsa"
public_key_file = "/root/ocp-install-dir2/id_rsa.pub"