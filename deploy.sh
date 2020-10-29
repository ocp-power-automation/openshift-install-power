#!/bin/bash
: '
Copyright (C) 2020 IBM Corporation
Licensed under the Apache License, Version 2.0 (the “License”);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an “AS IS” BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'
#-------------------------------------------------------------------------
set -e

#-------------------------------------------------------------------------
# Display help
#-------------------------------------------------------------------------
function help {
  cat <<-EOF

Automation for deploying OpenShift 4.X on PowerVS

Usage:
  ./deploy.sh [command] [<args> [<value>]]

Available commands:
  setup       Install all required packages/binaries in current directory
  variables   Interactive way to populate the variables file
  create      Create an OpenShift cluster
  destroy     Destroy an OpenShift cluster
  output      Display the cluster information. Runs terraform output [NAME]
  help        Display this information

Where <args>:
  -trace      Enable tracing of all executed commands
  -verbose    Enable verbose for terraform console
  -var        Terraform variable to be passed to the create/destroy command
  -var-file   Terraform variable file name in current directory. (By default using var.tfvars)

Submit issues at: ${GIT_URL}/issues

EOF
  exit 0
}

OCP_RELEASE=${OCP_RELEASE:-"4.5"}
ARTIFACTS_VERSION=${ARTIFACTS_VERSION:-"release-4.5"}
#ARTIFACTS_VERSION="v4.5.3"
#ARTIFACTS_VERSION="master"

TF='./terraform'
CLI_PATH='./ibmcloud'

ARTIFACTS_DIR="automation"
LOGFILE="ocp4-upi-powervs_$(date "+%Y%m%d%H%M%S")"
GIT_URL="https://github.com/ocp-power-automation/ocp4-upi-powervs"
TRACE=0
TF_TRACE=0

#-------------------------------------------------------------------------
# Trap ctrl-c interrupt and call ctrl_c()
#-------------------------------------------------------------------------
trap ctrl_c INT
function ctrl_c() {
  if [[ -f ./.terraform.tfstate.lock.info || -f ./"$ARTIFACTS_DIR"/.terraform.tfstate.lock.info ]]; then
    error "Terraform process was running when the script was interrupted. Please run create command again to continue OR destroy command to clean up resources."
  else
    error "Exiting on user interrupt!"
  fi
}

#-- Colors escape seqs
YEL='\033[1;33m'
CYN='\033[0;36m'
GRN='\033[1;32m'
RED='\033[1;31m'
PUR="\033[1;35m"
NRM='\033[0m'

function log {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} $1"
}
function warn {
  echo -e "${YEL}[${FUNCNAME[1]}]${NRM} ${YEL}WARN${NRM}: $1"
}
function failure {
  echo -e "${PUR}[${FUNCNAME[1]}]${NRM} ${PUR}FAILED${NRM}: $1"
}
function success {
  echo -e "${GRN}[${FUNCNAME[1]}]${NRM} ${GRN}SUCCESS${NRM}: $1"
}
function error {
  echo -e "${RED}[${FUNCNAME[1]}]${NRM} ${RED}ERROR${NRM}: $1"
  ret_code=$2
  [[ "$ret_code" == "" ]] && ret_code=-1
  exit $ret_code
}
function debug_switch {
  if [[ $TRACE == 0 ]]; then
    return
  fi

  if [[ $- =~ x ]]; then
    set +x
  else
    set -x
  fi
}

#-------------------------------------------------------------------------
# Display the cluster output variables
#-------------------------------------------------------------------------
function output {
  cd ./"$ARTIFACTS_DIR"
  TF="../$TF"
  $TF output $output_var
}

#-------------------------------------------------------------------------
# Util for retrying any command, special case for curl downloads
#-------------------------------------------------------------------------
function retry {
  tries=$1
  cmd=$2
  for i in $(seq 1 "$tries"); do
    echo "Attempt: $i/$tries"
    ret_code=0
    $cmd || ret_code=$?
    if [ $ret_code = 0 ]; then
      break
    elif [ "$i" == "$tries" ]; then
      error "All retry attempts failed! Please try running the script again after some time" $ret_code
    else
      sleep 1s
    fi
  done
}

#-------------------------------------------------------------------------
# # Check if terraform is already running
#-------------------------------------------------------------------------
function is_terraform_running {
  MAX_WAIT_TIME=3600
  WAIT_TIME=0

  if [[ -f ./.terraform.tfstate.lock.info ]]; then warn "Terraform process is already running... waiting for it to finish"; fi

  while [[ -f ./.terraform.tfstate.lock.info  && $WAIT_TIME -lt $MAX_WAIT_TIME ]]; do
    sleep 30
    let "WAIT_TIME+=30"
  done

  if [[ -f ./.terraform.tfstate.lock.info ]]; then error "Terraform process is running for more than an hour. Retry after some time"; fi
}

#-------------------------------------------------------------------------
# Retry and monitor the terraform commands
#-------------------------------------------------------------------------
function retry_terraform {
  tries=$1
  action=$2
  options=$3
  cmd="$TF $action $3"

  is_terraform_running

  for i in $(seq 1 "$tries"); do
    LOG_FILE="../logs/${LOGFILE}_${action}_$i.log"
    echo "Attempt: $i/$tries"
    {
    echo "========================"
    echo "Attempt: $i/$tries"
    echo "$cmd"
    echo "========================"
    } >> "$LOG_FILE"

    if [[ "$TF_TRACE" -eq 0 ]]; then
      $cmd >> "$LOG_FILE" 2>&1 &
    else
      $cmd | tee "$LOG_FILE" 2>&1 &
    fi
    tpid=$!

    # Give some breather for TF lock file to appear
    sleep 10

    # Wait until TF lock file is present OR log file is updated in last 30s
    while [[ -f ./.terraform.tfstate.lock.info ]] || [[ $(find ${LOGFILE} -mmin -0.5 -print) ]]; do
      sleep 30
      # CAN PROVIDE HACKS HERE
      # Keep check on bastion
      # Keep check on rhcos nodes
    done

    errors=$(grep "Error:" "$LOG_FILE" | sort | uniq)
    if [ -z "${errors}" ]; then
      # terraform command completed without any errors
      break
    else
      log "${errors[@]}"
      # All tries exhausted
      if [ "$i" == "$tries" ]; then
        error "Terraform command failed after $tries attempts! Please check the log files"
      fi
      # Nothing to do other than retry
      warn "Some issues were seen while running the terraform command. Attempting to run again..."
      sleep 10s
    fi
  done
  log "Completed running the terraform command."
}

#-------------------------------------------------------------------------
# Initialize and validate the Terraform code with plugins
#-------------------------------------------------------------------------
function init_terraform {
  log "Initializing Terraform plugins..."
  retry 5 "$TF init"
  log "Validating Terraform code..."
  $TF validate
}

#-------------------------------------------------------------------------
# Verify if pull-secret.txt exists
# Check if SSH key-pair is provided else use users key or create a new one
#-------------------------------------------------------------------------
function verify_data {
  if [ -s "./$ARTIFACTS_DIR/data/pull-secret.txt" ]; then
    log "Found pull-secret.txt in data directory"
  elif [ -s "./pull-secret.txt" ]; then
    log "Found pull-secret.txt in current directory"
    cp -f pull-secret.txt ./"$ARTIFACTS_DIR"/data/
  else
    error "No pull-secret.txt file found in current directory"
  fi
  if [ -f "./$ARTIFACTS_DIR/data/id_rsa" ] && [ -f "./$ARTIFACTS_DIR/data/id_rsa.pub" ]; then
    log "Found id_rsa & id_rsa.pub in data directory"
  elif [ -f "./id_rsa" ] && [ -f "./id_rsa.pub" ]; then
    log "Found id_rsa & id_rsa.pub in current directory"
    cp -f ./id_rsa ./id_rsa.pub ./"$ARTIFACTS_DIR"/data/
  else
    warn "Creating new SSH key-pair..."
    ssh-keygen -t rsa -f ./id_rsa -N ''
    cp -f "./id_rsa" "./id_rsa.pub" ./"$ARTIFACTS_DIR"/data/
  fi
}

#-------------------------------------------------------------------------
# Common checks for apply and destroy functions
#-------------------------------------------------------------------------
function precheck {
  debug_switch
  [ "${CLOUD_API_KEY}" == "" ] && error "Please export CLOUD_API_KEY"
  [ "${RHEL_SUBS_PASSWORD}" != "" ] && export TF_VAR_rhel_subscription_password="$RHEL_SUBS_PASSWORD"
  debug_switch
  # Run setup if no artifacts
  [ ! -d $ARTIFACTS_DIR ] && warn "Cannot find artifacts directory... running setup command" && setup

  if [ -z "$vars" ] && [ -f "var.tfvars" ]; then
    vars="-var-file ../var.tfvars"
  else
    warn "No variables specified or var.tfvars does not exist.. running variables command" && variables
    vars="-var-file ../var.tfvars"
  fi
  verify_data
  debug_switch
  export TF_VAR_ibmcloud_api_key="$CLOUD_API_KEY"
  debug_switch

  cd ./"$ARTIFACTS_DIR"
  TF="../$TF"
  init_terraform
}

#-------------------------------------------------------------------------
# Create the cluster
#-------------------------------------------------------------------------
function apply {
  precheck
  log "Running terraform apply... please wait"
  retry_terraform 3 apply "$vars -auto-approve -input=false"
  $TF output
  success "Congratulations! create command completed"
}

#-------------------------------------------------------------------------
# Destroy the cluster
#-------------------------------------------------------------------------
function destroy {
  precheck
  log "Running terraform destroy... please wait"
  retry_terraform 2 destroy "$vars -auto-approve -input=false"
  success "Done! destroy commmand completed"
}

#-------------------------------------------------------------------------
# Util for questions prompt
# 1.multi-choice 2.free-style input 3.free-style with a default value
#-------------------------------------------------------------------------
function question {
  value=""
  # question to ask
  message=$1
  # array of options eg: "a b c".
  options=($2)
  len=${#options[@]}
  force_select=$3

  if [[ $options == "-sensitive" ]]; then
    log "> $message"
    read -s value
    return
  fi

  if [[ $len -gt 1 ]] || [[ -n "$force_select" ]]; then
    # Multi-choice
    # Allow select prompt even for if a single option.
    log "> $message"
    select value in ${options[@]}
    do
    if [ "$value" == "" ]; then
      echo 'Invalid value... please re-select'
    else
      break
    fi
    done
  elif [[ $len -eq 1 ]]; then
    # Input question with default value
    # If only 1 option is sent then use it for default value prompt.
    log "> $message (${options[0]})"
    read -p "? " value
    [[ "${value}" == "" ]] && value="${options[0]}"
  else
    # Input question without any default value.
    log "> $message"
    read -p "? " value
  fi
  echo "- You have answered: $value"
}

#-------------------------------------------------------------------------
# Interactive prompts for nodes configuration
#-------------------------------------------------------------------------
function variables_nodes {
  question "Do you want to use the default configuration for all the cluster nodes?" "yes no"
  if [ "${value}" == "yes" ]; then
    {
      echo "bastion = {memory = \"16\", processors = \"1\", \"count\" = 1}"
      echo "bootstrap = {memory = \"16\", processors = \"0.5\", \"count\" = 1}"
      echo "master = {memory = \"16\", processors = \"0.5\", \"count\" = 3}"
      echo "worker = {memory = \"32\", processors = \"0.5\", \"count\" = 2}"
    } >> "$VAR_TEMPLATE"
    return
  fi

  # Bastion node config
  question "Do you want to use the default configuration for bastion node? (memory=16g processors=1 count=1)" "yes no"
  if [ "${value}" == "yes" ]; then
    echo "bastion = {memory = \"16\", processors = \"1\", \"count\" = 1}" >> "$VAR_TEMPLATE"
  else
    question "Enter the memory required for bastion nodes" "16"
    memory="${value}"
    question "Enter the processors required for bastion nodes" "1"
    proc="${value}"
    question "Select the count of bastion nodes" "1 2"
    count="${value}"
    echo "bastion = {memory = \"$memory\", processors = \"$proc\", \"count\" = $count}" >> "$VAR_TEMPLATE"
  fi

  # Bootstrap node config
  question "Do you want to use the default configuration for bootstrap node? (memory=16 processors=0.5)" "yes no"
  if [ "${value}" == "yes" ]; then
    echo "bootstrap = {memory = \"16\", processors = \"0.5\", \"count\" = 1}" >> "$VAR_TEMPLATE"
  else
    question "Enter the memory required for bootstrap node" "16"
    memory="${value}"
    question "Enter the processors required for bootstrap node" "0.5"
    proc="${value}"
    echo "bootstrap = {memory = \"$memory\", processors = \"$proc\", \"count\" = 1}" >> "$VAR_TEMPLATE"
  fi

  # Master nodes config
  question "Do you want to use the default configuration for master nodes? (memory=16 processors=0.5 count=3)" "yes no"
  if [ "${value}" == "yes" ]; then
    echo "master = {memory = \"16\", processors = \"0.5\", \"count\" = 3}" >> "$VAR_TEMPLATE"
  else
    question "Enter the memory required for master nodes" "16"
    memory="${value}"
    question "Enter the processors required for master nodes" "0.5"
    proc="${value}"
    question "Select the count of master nodes" "3 5"
    count="${value}"
    echo "master = {memory = \"$memory\", processors = \"$proc\", \"count\" = $count}" >> "$VAR_TEMPLATE"
  fi

  # Worker nodes config
  question "Do you want to use the default configuration for worker nodes? (memory=32 processors=0.5 count=2)" "yes no"
  if [ "${value}" == "yes" ]; then
    echo "worker = {memory = \"32\", processors = \"0.5\", \"count\" = 2}" >> "$VAR_TEMPLATE"
  else
    question "Enter the memory required for worker nodes" "32"
    memory="${value}"
    question "Enter the processors required for worker nodes" "0.5"
    proc="${value}"
    question "Enter the count of worker nodes" "2"
    count="${value}"
    echo "worker = {memory = \"$memory\", processors = \"$proc\", \"count\" = $count}" >> "$VAR_TEMPLATE"
  fi
}

#-------------------------------------------------------------------------
# Interactive prompts to populate the var.tfvars file
#-------------------------------------------------------------------------
function variables {
  debug_switch
  [ "${CLOUD_API_KEY}" == "" ] && error "Please export CLOUD_API_KEY"
  debug_switch
  # Run setup if no artifacts
  [ ! -d $ARTIFACTS_DIR ] && warn "Cannot find artifacts directory... running setup command" && setup
  if [ -s "./pull-secret.txt" ]; then
    log "Found pull-secret.txt in current directory"
    cp -f pull-secret.txt ./"$ARTIFACTS_DIR"/data/
  else
    debug_switch
    question "Enter the pull-secret" "-sensitive"
    if [[ "${value}" != "" ]]; then
      echo "${value}" > ./"$ARTIFACTS_DIR"/data/pull-secret.txt
    fi
    debug_switch
  fi

  if [ -f "./id_rsa" ] && [ -f "./id_rsa.pub" ]; then
    log "Found id_rsa & id_rsa.pub in current directory"
    cp -f ./id_rsa ./id_rsa.pub ./"$ARTIFACTS_DIR"/data/
  elif [ -f "$HOME/.ssh/id_rsa" ] && [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    question "SSH key-pair to use?" "$HOME/.ssh/ <Create_New_Keypair>"
    if [ "${value}" == "$HOME/.ssh/" ]; then
      cp -f "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_rsa.pub" ./"$ARTIFACTS_DIR"/data/
    fi
  fi
  VAR_TEMPLATE="./var.tfvars.tmp"
  VAR_FILE="./var.tfvars"
  rm -f "$VAR_TEMPLATE" "$VAR_FILE"

  log "Trying to login with the provided CLOUD_API_KEY..."
  debug_switch
  $CLI_PATH login --apikey "$CLOUD_API_KEY" -q
  debug_switch

  ALL_SERVICE_INSTANCE=$($CLI_PATH pi service-list --json| grep "Name" | cut -f4 -d'"')
  [ -z "$ALL_SERVICE_INSTANCE" ] && error "No service instance found in your account"

  question "Select the Service Instance name to use:" "$ALL_SERVICE_INSTANCE" yes
  service_instance="$value"

  CRN=$($CLI_PATH pi service-list | grep "${service_instance}" | awk '{print $1}')
  $CLI_PATH pi service-target "$CRN"

  log "Gathering information from the selected Service Instance... Please wait"
  ZONE=$(echo "$CRN" | cut -f6 -d":")
  REGION=$(echo "$ZONE" | sed 's/-*[0-9].*//')
  SERVICE_INSTANCE_ID=$(echo "$CRN" | cut -f8 -d":")

  ALL_IMAGES_COUNT=$($CLI_PATH pi images --json | grep name | cut -f4 -d'"' | wc -l)
  [ "$ALL_IMAGES_COUNT" -lt 2 ] && error "There should be atleast 2 images (RHEL and RHCOS), found $ALL_IMAGES_COUNT"
  ALL_IMAGES=$($CLI_PATH pi images --json | grep name | cut -f4 -d'"')

  # FIXME: Filter out only pub-vlan from the list; using grep currently
  ALL_NETS=$($CLI_PATH pi nets --json| grep name | cut -f4 -d'"' | grep -v pub-net | grep -v public-)
  [ -z "$ALL_NETS" ] && error "No private network found"

  ALL_OCP_VERSIONS=$(curl -sL https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp/| grep "$OCP_RELEASE" | cut -f7 -d '>' | cut -f1 -d '/')
  [ -z "$ALL_OCP_VERSIONS" ] && error "No OCP versions found for version $OCP_RELEASE... Ensure you have set correct OCP_RELEASE"


  # TODO: Get region from a map of `zone:region` or any other good way
  {
    echo "ibmcloud_region = \"${REGION}\""
    echo "ibmcloud_zone = \"${ZONE}\""
    echo "service_instance_id = \"${SERVICE_INSTANCE_ID}\""
  } >> $VAR_TEMPLATE

  # RHEL image name
  question "Select the RHEL image to use for bastion node:" "$ALL_IMAGES" yes
  echo "rhel_image_name =  \"${value}\"" >> $VAR_TEMPLATE

  # RHCOS image name
  question "Select the RHCOS image to use for cluster nodes:" "$ALL_IMAGES" yes
  echo "rhcos_image_name =  \"${value}\"" >> $VAR_TEMPLATE

  # PowerVS private network
  question "Select the private network to use:" "$ALL_NETS" yes
  echo "network_name =  \"${value}\"" >> $VAR_TEMPLATE

  # OpenShift mirror links
  question "Select the OCP version to use:" "$ALL_OCP_VERSIONS" yes
  OCP_IURL="https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp/${value}/openshift-install-linux.tar.gz"
  OCP_CURL="https://mirror.openshift.com/pub/openshift-v4/ppc64le/clients/ocp/${value}/openshift-client-linux.tar.gz"
  echo "openshift_install_tarball =  \"${OCP_IURL}\"" >> $VAR_TEMPLATE
  echo "openshift_client_tarball =  \"${OCP_CURL}\"" >> $VAR_TEMPLATE


  # Cluster id
  question "Enter a short name to identify the cluster" "test-ocp"
  echo "cluster_id_prefix = \"${value}\"" >> $VAR_TEMPLATE

  # Cluster domain
  question "Enter a domain name for the cluster" "ibm.com"
  echo "cluster_domain = \"${value}\"" >> $VAR_TEMPLATE

  # Storage
  question "Do you need NFS storage to be configured?" "yes no"
  if [ "${value}" == "yes" ]; then
    question "Enter the NFS volume size(GB)" "300"
    echo "storage_type = \"nfs\"" >> $VAR_TEMPLATE
    echo "volume_size = \"${value}\"" >> $VAR_TEMPLATE
  elif [ "${value}" == "no" ]; then
    echo "storage_type = \"none\"" >> $VAR_TEMPLATE
  fi

  # Nodes configuration
  variables_nodes

  question "Enter RHEL subscription username for bastion nodes"
  echo "rhel_subscription_username = \"${value}\"" >> $VAR_TEMPLATE
  if [ "${value}" == "" ]; then
    warn "Skipping subscription information since no username is provided"
  else
    debug_switch
    if [[ "${RHEL_SUBS_PASSWORD}" != "" ]]; then
      warn "Using the subscription password from environment variables"
    else
      question "Enter the password for above username. WARNING: If you do not wish to store the subscription password please export RHEL_SUBS_PASSWORD" "-sensitive"
      if [[ "${value}" != "" ]]; then
        echo "rhel_subscription_password = \"${value}\"" >> $VAR_TEMPLATE
      fi
    fi
    debug_switch
  fi

  echo "private_key_file = \"data/id_rsa\"" >> $VAR_TEMPLATE
  echo "public_key_file = \"data/id_rsa.pub\"" >> $VAR_TEMPLATE

  cp $VAR_TEMPLATE $VAR_FILE
  rm -f $VAR_TEMPLATE
  success "variables command completed!"
}

#-------------------------------------------------------------------------
# Download the ocp4-upi-powervs tag/branch artifact
#-------------------------------------------------------------------------
function setup_artifacts() {
  log "Downloading code artifacts $ARTIFACTS_VERSION in ./$ARTIFACTS_DIR"
  retry 2 "curl -fsSL $GIT_URL/archive/$ARTIFACTS_VERSION.zip -o ./automation.zip"
  unzip -o "./automation.zip" > /dev/null 2>&1
  rm -rf ./"$ARTIFACTS_DIR" ./automation.zip
  cp -rf "ocp4-upi-powervs-$ARTIFACTS_VERSION" ./"$ARTIFACTS_DIR"
  rm -rf "ocp4-upi-powervs-$ARTIFACTS_VERSION"
}

#-------------------------------------------------------------------------
# Install latest terraform in current directory
# If latest is available in System PATH then use symlink
#-------------------------------------------------------------------------
function setup_terraform {
  TF_LATEST=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d'"' -f4)
  EXT_PATH=$(which terraform 2> /dev/null || true)

  if [[ -f $TF && $($TF version | grep 'Terraform v0') == "Terraform ${TF_LATEST}" ]]; then
    log "Terraform latest version already installed"
  elif [[ -n "$EXT_PATH" && $($EXT_PATH version | grep 'Terraform v0') == "Terraform ${TF_LATEST}" ]]; then
    rm -f "$TF"
    ln -s "$EXT_PATH" "$TF"
    log "Terraform latest version already installed on the system"
  else
    log "Installing the latest version of Terraform..."
    retry 5 "curl --connect-timeout 30 -fsSL https://releases.hashicorp.com/terraform/${TF_LATEST:1}/terraform_${TF_LATEST:1}_${OS}_amd64.zip -o ./terraform.zip"
    unzip -o ./terraform.zip  >/dev/null 2>&1
    rm -f ./terraform.zip
    chmod +x $TF
  fi
  $TF version
}

#-------------------------------------------------------------------------
# Install latest power-iaas plugin
#-------------------------------------------------------------------------
function setup_poweriaas() {
  PLUGIN_OP=$("$CLI_PATH" plugin list -q | grep power-iaas || true)
  if [[ "$PLUGIN_OP" != "" ]]; then
    log "Plugin power-iaas already installed"
  else
    log "Installing power-iaas plugin..."
    $CLI_PATH plugin install power-iaas -f -q > /dev/null 2>&1
  fi
}

#-------------------------------------------------------------------------
# Install latest ibmcloud cli in current directory
# If latest is available in System PATH then use symlink
#-------------------------------------------------------------------------
function setup_ibmcloudcli() {
  CLI_LATEST=$(curl -s https://api.github.com/repos/IBM-Cloud/ibm-cloud-cli-release/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//')
  EXT_PATH=$(which ibmcloud 2> /dev/null || true)

  if [[ -f $CLI_PATH && $($CLI_PATH -v | sed 's/.*version //' | sed 's/+.*//') == "${CLI_LATEST}" ]]; then
    log "IBM-Cloud CLI latest version already installed"
  elif [[ -n "$EXT_PATH" && $($EXT_PATH -v | sed 's/.*version //' | sed 's/+.*//') == "${CLI_LATEST}" ]] ; then
    rm -f "$CLI_PATH"
    ln -s "$EXT_PATH" "$CLI_PATH"
    log "IBM-Cloud CLI latest version already installed on the system"
  else
    log "Installing the latest version of IBM-Cloud CLI..."
    retry 2 "curl -fsSL https://clis.cloud.ibm.com/download/bluemix-cli/latest/${CLI_OS}/archive -o ./archive"
    if [[ "$OS" != "windows" ]]; then
      tar -xvzf "./archive" >/dev/null 2>&1
    else
      unzip -o "./archive" >/dev/null 2>&1
    fi
    cp -f ./IBM_Cloud_CLI/ibmcloud "${CLI_PATH}"
    rm -rf "./archive" ./IBM_Cloud_CLI*
  fi
  ${CLI_PATH} -v
}

#-------------------------------------------------------------------------
# Install the latest ibmcloud cli, power-iaas plugin and terraform
# Also download the ocp-power-automation/ocp4-upi-powervs artifact
#-------------------------------------------------------------------------
function setup {
  if [[ "$PACKAGE_MANAGER" != "" ]]; then
    log "Installing dependency packages"
    if [[ "$OS" == "darwin" ]]; then
      $PACKAGE_MANAGER cask install osxfuse XQuartz > /dev/null 2>&1
      $PACKAGE_MANAGER install -f curl unzip > /dev/null 2>&1
    else
      $PACKAGE_MANAGER update -y > /dev/null 2>&1
      $PACKAGE_MANAGER install -y curl unzip > /dev/null 2>&1
    fi
  fi

  if [[ -f ./"$ARTIFACTS_DIR"/terraform.tfstate ]]; then
    if [[ $($TF version | grep 'Terraform v0') != "Terraform v$(grep terraform_version ./"$ARTIFACTS_DIR"/terraform.tfstate | awk '{print $2}' |  cut -d'"' -f2)" ]]; then
      error "Existing state file was created using a different terraform version. Please destroy the resources by running the destroy command."
    fi
    if [[ $($TF state list -state=./"$ARTIFACTS_DIR"/terraform.tfstate | wc -l) -gt 0 ]]; then
      error "Existing state file contains resources. Please destroy the resources by running the destroy command."
    fi
  fi

  setup_ibmcloudcli
  setup_poweriaas
  setup_terraform
  setup_artifacts
  success "setup command completed!"
}



function main {
  mkdir -p ./logs
  vars=""

  # Only use sudo if not running as root
  [ "$(id -u)" -ne 0 ] && SUDO=sudo || SUDO=""

  PLATFORM=$(uname)
  case "$PLATFORM" in
    "Darwin")
      OS="darwin"; CLI_OS="osx"; PACKAGE_MANAGER="brew"
      ;;
    "Linux")
      # Linux distro, e.g "Ubuntu", "RedHatEnterpriseWorkstation", "RedHatEnterpriseServer", "CentOS", "Debian"
      OS="linux"; CLI_OS="linux64"
      DISTRO=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om || echo "")
      if [[ "$DISTRO" != *Ubuntu* &&  "$DISTRO" != *Red*Hat* && "$DISTRO" != *CentOS* && "$DISTRO" != *Debian* && "$DISTRO" != *RHEL* && "$DISTRO" != *Fedora* ]]; then
        warn "Linux has only been tested on Ubuntu, RedHat, Centos, Debian and Fedora distrubutions please let us know if you use this utility on other Distros"
      fi
      if [[ "$DISTRO" == *Ubuntu* || "$DISTRO" == *Debian*  ]]; then
        PACKAGE_MANAGER="$SUDO apt-get"
      elif [[ "$DISTRO" == *Fedora* ]]; then
        PACKAGE_MANAGER="$SUDO dnf"
      else
        PACKAGE_MANAGER="$SUDO yum"
      fi
      ;;
    "MINGW64"*|"CYGWIN"*|"MSYS"*)
      OS="windows"; CLI_OS="win64"; PACKAGE_MANAGER=""
      ;;
    *)
      warn "Only MacOS and Linux systems are supported"
      error "Unsupported platform: ${PLATFORM}"
      exit 1
      ;;
  esac

  # Parse commands and arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    "-trace")
      warn "Enabling tracing of all executed commands"
      set -x
      TRACE=1
      ;;
    "-verbose")
      warn "Enabling verbose for terraform console"
      TF_TRACE=1
      ;;
    "-var")
      shift
      var="$1"
      vars+=" -var $var"
      ;;
    "-var-file")
      shift
      varfile="$1"
      [[ ! -s "$varfile" ]] && error "File $varfile does not exist"
      vars+=" -var-file ../$varfile"
      ;;
    "setup")
      ACTION="setup"
      ;;
    "variables")
      ACTION="variables"
      ;;
    "create")
      ACTION="create"
      ;;
    "destroy")
      ACTION="destroy"
      ;;
    "output")
      ACTION="output"
      shift
      output_var="$1"
      break
      ;;
    "help")
      ACTION="help"
      ;;
    esac
    shift
  done

  case "$ACTION" in
    "setup")      setup;;
    "variables")  variables;;
    "create")     apply;;
    "destroy")    destroy;;
    "output")     output;;
    *)            help;;
  esac
}

main "$@"
