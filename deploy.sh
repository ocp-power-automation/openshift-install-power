#!/bin/bash
set -e
#

TF='./terraform'
TMPDIR=${TMPDIR:-"/tmp"}
LOGFILE=".ocp4-upi-powervs.log"
GIT_URL="https://github.com/ocp-power-automation/ocp4-upi-powervs"
source ./errors.sh
PLATFORM=$(uname)
DISTRO=""
CLI_PATH='./IBM_Cloud_CLI/ibmcloud'
CLI_VERSION=${CLI_VERSION:-"latest"}

#------------------------------------------------------------------------------
#-- ${FUNCNAME[1]} == Calling function's name
#-- Colors escape seqs
YEL='\033[1;33m'
CYN='\033[0;36m'
GRN='\033[1;32m'
RED='\033[1;31m'
PUR="\033[1;35m"
NRM='\033[0m'

trap ctrl_c INT
function ctrl_c() {
  echo "User interrupted termination!"
  exit 0
}
function log {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} $1"
}
function warn {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} ${YEL}WARN${NRM}: $1"
}
function failure {
  echo -e "${CYN}[${FUNCNAME[1]}]${NRM} ${PUR}FAILED${NRM}: $1"
}
function error {
    echo -e "${CYN}[${FUNCNAME[1]}]${NRM} ${RED}ERROR${NRM}: $1"
    rc=$2
    if [ "$rc" == "" ]; then
        rc=-1
    fi;
    exit $rc
}
function retry {
    tries=$1
    cmd=$2
    for i in $(seq 1 "$tries"); do
        echo "Attempt: $i/$tries"
        $cmd
        rc=$?
        if [ $rc = 0 ]; then
            break
        elif [ "$i" == "$tries" ]; then
            error "All retry attempts failed! Please try running the script again after some time." $rc
        else
            sleep 1s
        fi
    done
}

function retry_terraform {
    tries=$1
    cmd=$2
    for i in $(seq 1 "$tries"); do
        fatal_errors=()
        LOGFILE=${LOGFILE}_$i
        echo "Attempt: $i/$tries"
        echo "========================" >>$LOGFILE
        echo "Attempt: $i/$tries" >>$LOGFILE
        echo "$cmd" >>$LOGFILE
        echo "========================" >>$LOGFILE
        $cmd >>$LOGFILE 2>&1 &
        tpid=$!
        loop_itr=$(ps | grep "$tpid")
        while [ "$loop_itr" != "" ]; do
            sleep 30
            loop_itr=$(ps | grep "$tpid")
            # CAN PROVIDE HACKS HERE
            # Keep check on bastion
            # Keep check on rhcos nodes
        done
        errors=$(grep -i ERROR $LOGFILE | uniq)
        if [ -z "$errors" ]; then
            # terraform command completed without any errors
            break
        else
            # Handle errors
            # Input variables are invalid
            # Can a re-run help?
            # Bastion is not creating

            # Catch known issues
            find_fatal_errors
            if [ ! -z "$fatal_errors" ]; then
                failure "Please correct the following errors and run the script again."
                error "${fatal_errors[@]}"
            fi

            # All tries exhausted
            if [ "$i" == "$tries" ]; then
                log "${errors[@]}"
                error "Terraform command failed after $tries attempts! Please destroy and run the script again after some time." $rc
            fi

            # Nothing to do other than retry
            log "${errors[@]}"
            warn "Some issues seens while running the terraform command. Attempting to run again..."
            sleep 10s
        fi
    done
    log "Completed running the terraform command."
}

function init_terraform {
    if [[ "$DISTRO" == *Ubuntu* ]]; then
          PACKAGE_MANAGER="apt-get"
    else
          PACKAGE_MANAGER="yum"
    fi

    if [ -f $TF ]; then
        log "Terraform binary path exsits."
        if $TF version; then
            log "Terraform already installed."
        fi
    else
        log "Installing dependency packages"
        $PACKAGE_MANAGER update -y
        $PACKAGE_MANAGER install -y git curl unzip
        log "Installing Terraform binary..."
        rm -rf "$TMPDIR"/terraform.zip
        rm -rf $TF
        mkdir -p "$TMPDIR"
        #curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest| jq -r ."tag_name"
        retry 5 "curl --connect-timeout 30 -fsSL https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.4_linux_amd64.zip -o $TMPDIR/terraform.zip"
        unzip "$TMPDIR"/terraform.zip
        $TF version
    fi
    log "Initializing Terraform plugins..."
    retry 5 "$TF init"
    log "Validating Terraform code..."
    $TF validate
}

function verify_data {
    if [ -s "./data/pull-secret.txt" ]; then
        log "Found pull-secret.txt in ./data directory."
    else
        error "No pull-secret.txt file found in ./data directory."
    fi
    if [ -f "./data/id_rsa" ] && [ -f "data/id_rsa.pub" ]; then
        log "Found id_rsa & id_rsa.pub in ./data directory."
    elif [ -f "$HOME/.ssh/id_rsa" ] && [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        log "Found id_rsa & id_rsa.pub in $HOME/.ssh directory."
    else
        warn "No id_rsa & id_rsa.pub found in data directory, Creating new key-pair..."
        rm -rf ./data/id_rsa*
        ssh-keygen -t rsa -f ./data/id_rsa -N ''
    fi
}

function verify_var_file {
    if [ -s "$1" ]; then
        log "Found $1"
    else
        error "File $1 does not exist."
    fi
}

function install_ibmcloudcli() {
    if [[ "$PLATFORM" == *Linux* || "$PLATFORM" == *Darwin* || "$PLATFORM" == *MINGW* ]]; then
        if [[ "$PLATFORM" == *Linux* ]]; then
            CLI_REF=$(curl -s https://clis.cloud.ibm.com/download/bluemix-cli/$CLI_VERSION/linux64/archive)
        elif [[ "$PLATFORM" == *Darwin* ]]; then
            CLI_REF=$(curl -s https://clis.cloud.ibm.com/download/bluemix-cli/$CLI_VERSION/osx/archive)
        else
            CLI_REF=$(curl -s https://clis.cloud.ibm.com/download/bluemix-cli/$CLI_VERSION/win64/archive)
        fi
        CLI_URL=$(echo $CLI_REF | sed 's/.*href=\"//' | sed 's/".*//')
        ARTIFACT=$(basename $CLI_URL)
        curl -fsSL $CLI_URL -o $ARTIFACT

        if [[ "$PLATFORM" == *Linux* || "$PLATFORM" == *Darwin* ]]; then
            tar -xvzf $ARTIFACT >/dev/null 2>&1
        else
            unzip -o $ARTIFACT >/dev/null 2>&1
        fi
        $CLI_PATH -v
    else
        echo "$PLATFORM not supported"
        exit 0
    fi
}

function install_poweriaas() {
    PLUGIN_OP=$($CLI_PATH plugin list | grep power-iaas)
    if [[ "$PLUGIN_OP" != "" ]]; then
        echo "power-iaas plugin already installed"
    else
        echo "Installing power-iaas plugin"
        $CLI_PATH plugin install power-iaas -f -q >> install_poweriaas.log 2>&1
    fi
}

function setup_ibmcloudcli() {
    if [[ -f $CLI_PATH ]]; then
        CLI_VER=$($CLI_PATH -v | sed 's/.*version //' | sed 's/+.*//')
        if [[ "$CLI_VER" == "$CLI_VERSION" ]]; then
            echo "IBM-Cloud CLI already installed"
        else
            echo "Installing IBM-Cloud CLI"
            install_ibmcloudcli
        fi
    else
        echo "Installing IBM-Cloud CLI"
        install_ibmcloudcli
    fi
    install_poweriaas
}

function apply {
    rm -rf
    setup_ibmcloudcli
    init_terraform
    verify_data
    if [ -z "$vars" ] && [ -f "var.tfvars" ]; then
        vars="-var-file var.tfvars"
    fi
    log "Running terraform apply command..."
    retry_terraform 2 "$TF apply $vars -auto-approve -input=false"
    log "Congratulations! Terraform apply completed."
    $TF output
}

function destroy {
    init_terraform
    if [ -z "$vars" ] && [ -f "var.tfvars" ]; then
        vars="-var-file var.tfvars"
    fi
    log "Running terraform destroy command..."
    retry 2 "$TF destroy $vars -auto-approve -input=false"
    log "Done! Terraform destroy completed."
}
function help {
  cat <<-EOF

OpenShift automation on PowerVS

Usage:
  ./deploy.sh [command] [<args> <value>]

Available commands:
  setup       Install all required packages/binaries in current directory
  create      Create an OpenShift cluster
  destroy     Destroy an OpenShift cluster
  help        Help about any command

Where <args>:
  -var        Terraform variable to be passed to the apply/destroy command
  -var-file   Terraform variable file to be passed to the apply/destroy command. (Default: var.tfvars)
  -trace      Enable verbose tracing of all activity

Submit any issues to : ${GIT_URL}/issues
EOF
}
function main {
    rm -rf $LOGFILE*
    vars=""
    # Only use sudo if not running as root
    [ "$(id -u)" -ne 0 ] && SUDO=sudo || SUDO=""

    case "$PLATFORM" in
    "Darwin")
        ;;
    "Linux")
        # Linux distro, e.g "Ubuntu", "RedHatEnterpriseWorkstation", "RedHatEnterpriseServer", "CentOS", "Debian"
	DISTRO=$(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om || echo "")
        if [[ "$DISTRO" != *Ubuntu* &&  "$DISTRO" != *Red*Hat* && "$DISTRO" != *CentOS* && "$DISTRO" != *Debian* && "$DISTRO" != *RHEL* && "$DISTRO" != *Fedora* ]]; then
          warn "Linux has only been tested on Ubuntu, RedHat, Centos, Debian and Fedora distrubutions please let us know if you use this utility on other Distros"
        fi
        ;;
    *)
        warn "Only MacOS and Linux systems are supported."
        error "Unsupported platform: ${PLATFORM}"
        ;;
    esac

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        "-trace")
            warn "Enabling verbose tracing of all activity"
            set -x
            ;;
        "-var")
            shift
            var="$1"
            vars+=" -var $var"
            ;;
        "-var-file")
            shift
            varfile="$1"
            verify_var_file "$varfile"
            vars+=" -var-file $varfile"
            ;;
        "apply")
            ACTION="apply"
            ;;
        "destroy")
            ACTION="destroy"
            ;;
        "help")
            ACTION="help"
            ;;
        esac
        shift
    done

    case "$ACTION" in
    "")         apply;;
    "apply")    apply;;
    "destroy")  destroy;;
    *)          help;;
    esac
}

main "$@"
