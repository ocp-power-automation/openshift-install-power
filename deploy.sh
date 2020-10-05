#!/bin/bash
# Before running this script:
# git clone https://github.com/ocp-power-automation/ocp4-upi-powervs/
#

TF='./terraform'
TMPDIR=${TMPDIR:-"/tmp"}
LOGFILE=".ocp4-upi-powervs.log"
source ./errors.sh

#------------------------------------------------------------------------------
#-- ${FUNCNAME[1]} == Calling function's name
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
        LOGFILE=$LOGFILE_$i
        echo "Attempt: $i/$tries"
        echo "========================" >>$LOGFILE
        echo "Attempt: $i/$tries" >>$LOGFILE
        echo "$cmd" >>$LOGFILE
        echo "========================" >>$LOGFILE
        $cmd >>$LOGFILE 2>&1 &
        tpid=$!

        while $(ps | grep "$tpid"); do
            sleep 30
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
    if $TF version; then
        log "Terraform already installed."
    else
        log "Installing dependency packages"
        apt-get update -y
        apt-get install -y git curl unzip
        log "Installing Terraform binary..."
        rm -rf "$TMPDIR"/terraform.zip
        rm -rf $TF
        mkdir -p "$TMPDIR"
        retry 5 "curl --connect-timeout 30 -fsSL https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip -o $TMPDIR/terraform.zip"
        unzip "$TMPDIR"/terraform.zip
        $TF version
    fi
    if [ -s "$HOME/.local/share/terraform/plugins/registry.terraform.io/terraform-providers/ignition/terraform-provider-ignition_2.1.0_linux_amd64.zip" ]; then
        log "Ignition provider plugin already installed."
    else
        log "Setting up Ignition provider plugin..."
        mkdir -p "$HOME"/.local/share/terraform/plugins/registry.terraform.io/terraform-providers/ignition/
        curl --connect-timeout 30 -fsSL  https://github.com/community-terraform-providers/terraform-provider-ignition/releases/download/v2.1.0/terraform-provider-ignition_2.1.0_linux_amd64.zip -o "$HOME"/.local/share/terraform/plugins/registry.terraform.io/terraform-providers/ignition/terraform-provider-ignition_2.1.0_linux_amd64.zip
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

function apply {
    rm -rf 
    init_terraform
    verify_data
    if [ -z "$vars" ] && [ -f "var.tfvars" ]; then
        vars="-var-file var.tfvars"
    fi
    log "Running terraform apply command..."
    retry_terraform 2 "$TF apply $vars"
    log "Congratulations! Terraform apply completed."
    $TF output
}

function destroy {
    init_terraform
    if [ -z "$vars" ] && [ -f "var.tfvars" ]; then
        vars="-var-file var.tfvars"
    fi
    log "Running terraform destroy command..."
    $TF destroy $vars
    log "Done! Terraform destroy completed."
}

function main {
    rm -rf $LOGFILE*
    vars=""
    # Only use sudo if not running as root
    [ "$(id -u)" -ne 0 ] && SUDO=sudo || SUDO=""
    PLATFORM=$(uname)

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
