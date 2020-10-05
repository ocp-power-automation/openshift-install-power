#!/bin/bash
function find_fatal_errors {

SUB1="ibmcloud_api_key or bluemix_api_key or iam_token and iam_refresh_token must be provided"
SUB2="Provided API key could not be found"
if [[ "$errors" == *"$SUB1"* ]] || [[ "$errors" == *"$SUB2"* ]]; then
    fatal_errors+=("Invalid 'ibmcloud_api_key'")
fi


SUB1="lookup <region>.power-iaas.cloud.ibm.com: no such host"
SUB2="lookup .power-iaas.cloud.ibm.com: no such host"
if [[ "$errors" == *"$SUB1"* ]] || [[ "$errors" == *"$SUB2"* ]]; then
    fatal_errors+=("Invalid 'ibmcloud_region'")
fi

SUB1="unable to get admin image instance: unable to get new image instance"
SUB2="unable to get network, subnet, and possibly public network cidr for network ocp-net on cloud instance"
if [[ "$errors" == *"$SUB1"* ]] || [[ "$errors" == *"$SUB2"* ]]; then
    fatal_errors+=("Invalid 'ibmcloud_region' or 'ibmcloud_zone'")
fi

SUB1="does not have service (read-only) access to view tenant information"
SUB2="pi_cloud_instance_id must not be empty, got"
if [[ "$errors" == *"$SUB1"* ]] || [[ "$errors" == *"$SUB2"* ]]; then
    fatal_errors+=("Invalid 'service_instance_id'")
fi

SUB1="unable to get image"
if [[ "$errors" == *"$SUB1"* ]]; then
    fatal_errors+=("Unable to get the provided image 'rhel_image_name' or 'rhcos_image_name'")
fi
}

#Error: Failed to read variables file
