#!/bin/bash

set -Eeuo pipefail
DIR="$( cd "$( dirname "$( readlink -f "${BASH_SOURCE[0]}")" )" >/dev/null && pwd )/../.."
source "${DIR}/scripts/lib/config.sh"

mkdir -p "${CONFIG_DIR}"

# Default Configuration

CHAL_DIR=""
PROJECT=""
ZONE="europe-west3-c"
MIN_NODES="1"
MAX_NODES="3"
NUM_NODES="1"
MACHINE_TYPE="n1-standard-2"
CLUSTER_NAME="ctf-cluster-eu"
DOMAIN_NAME=""

config=""
read_config() {
    read -e -p "  $2: " -i "${!1}" "$1"
    line="${1}=\"${!1}\""
    config="${config}"$'\n'"${line}"
}

if [ -d ${CONFIG_DIR}/challenges ]; then
    CHAL_DIR=$(readlink ${CONFIG_DIR}/challenges)
    echo
    echo "Configuring cluster for challenge directory ${CHAL_DIR}"
else
    echo
    read -e -p "In which directory will challenges be stored?: " "CHAL_DIR"

    if [[ $CHAL_DIR == ~\/* ]]; then
        CHAL_DIR="${HOME}/${CHAL_DIR:2}"
    fi
    if [ ! -d "${CHAL_DIR}" ]; then
        echo "creating ${CHAL_DIR}"
        mkdir -p "${CHAL_DIR}"
    fi

    CHAL_DIR=$(realpath -L "${CHAL_DIR}")
    ln -nfs "${CHAL_DIR}" "${CONFIG_DIR}/challenges"
fi

echo
echo "= CLUSTER CONFIGURATION ="
echo
if test -f "${CONFIG_FILE}"; then
    echo
    echo " Reusing the last config file used ($(readlink -f "${CONFIG_FILE}"))."
    echo
    . "${CONFIG_FILE}"
else
    echo
    echo " Creating a new config file from scratch."
    echo
fi
echo
echo "== PROJECT NAME =="
echo
echo " Important: Make sure to update this field to your own project, or nothing will work"
echo
read_config PROJECT "Google Cloud Platform project name"
gcloud config set project "${PROJECT}"
echo
echo "= OPTIONAL CONFIGURATION ="
echo
echo " Note: You can leave everything below here as defaults."
echo
echo "== ZONE =="
echo
echo " Used for cluster configuration"
echo "  The zone defines the geographic location of the cluster."
echo
echo -n "  Available zones: (Loading...)"
gcloud compute zones list --format="csv[no-heading](name)" | xargs echo -e "\r  Available zones: "
echo
read_config ZONE "GCP Zone"
echo
echo "== AUTOSCALING =="
echo
echo " Used for autoscaling configuration"
echo "  A node is a VM, here you can configure how many VMs your cluster will have."
echo
read_config MIN_NODES "Minimum number of nodes"
read_config MAX_NODES "Maximum number of nodes"
read_config NUM_NODES "Initial number of nodes"
echo
echo "== VM CONFIGURATION =="
echo
echo " Select the VM type for the nodes"
echo "  n1-standard-4 means a 4 vCPUs VM of N1 gen with a standard RAM (15G for 4CPUs)."
echo "  n1-highmem-4 means a 4 vCPUs VM of N1 gen with more RAM (27G for 4CPUs)."
echo "  n1-highcpu-4 means a 4 vCPUs VM of N1 gen with less RAM (3G for 4CPUs)."
echo
echo -n "  Available machine types: (Loading...)"
gcloud compute machine-types list --zones="${ZONE}" --format="csv[no-heading](name)" | xargs echo -e "\r  Available machine types: "
echo
read_config MACHINE_TYPE "The VM machine type"
echo
echo "== CLUSTER NAME =="
echo
echo "  If you are reusing the same project for multiple CTFs, make sure this name is unique."
echo
read_config CLUSTER_NAME "Name of the cluster"
echo
echo "== DOMAIN NAME =="
echo
echo "  If you want to configure a domain name for the challenge, provide it below, otherwise leave it empty."
echo
read_config DOMAIN_NAME "Domain name (eg, k8s.ctfcompetititon.com)"
echo

CLUSTER_DIR="${CHAL_DIR}/kctf-conf/${PROJECT}_${ZONE}_${CLUSTER_NAME}"
CLUSTER_CONFIG="${CLUSTER_DIR}/cluster.conf"

echo "= SUMMARY ="
echo " This is the configuration for your cluster, please review it to make sure it is correct. It will be written to ${CLUSTER_CONFIG}"
echo "$config"
echo
echo " If you wish to change anything, just run this command again."

mkdir -p "${CLUSTER_DIR}"
echo "${config}" > "${CLUSTER_CONFIG}"

ln -fs "${CLUSTER_CONFIG}" "${CONFIG_FILE}"
