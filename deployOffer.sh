#!/bin/bash
#===============================================================================
#
#          FILE:  deployOffer.sh
#
#         USAGE:  ./deployOffer.sh -rgprefix <RG_PREFIX> -offertype <OFFER_TYPE> -wlsversion <WLS_VERSION> -ostype <OS_TYPE> -jdkversion <JDK_VERSION> -validationonly <true/false>
#
#   DESCRIPTION:  This script is used to deploy the Azure Offer by providing the required inputs such as Resource Group Prefix, Offer Type, OS Type, WLS Version & JDK Versino
#
#
#        AUTHOR:  Gurudutt Suryanarayana, Sanjay Mantoor
#       COMPANY:  Oracle Corporation
#       CREATED:  12/28/2021
#      REVISION:  ---
#===============================================================================

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils.sh

usage()
{
#  echo "$0 -rgprefix <RG_PREFIX> -offertype <OFFER_TYPE> -wlsversion <WLS_VERSION> -ostype <OS_TYPE> -jdkversion <JDK_VERSION>"
#  echo "Example: $0 -rgprefix test_rg -offertype singlenode -wlsversion 141100 -ostype rhel76 -jdkversion jd8"
#  exit 1

cat << USAGE >&2
Usage:
    -rgprefix             RG_PREFIX        Resource Group Prefix ex: test_rg
    -offertype            OFFER_TYPE       Offer Type - singlenode,admin,cluster,dynamicluster
    -wlsversion           WLS_VERSION      WebLogic Version  - 141100/122140/122130
    -ostype               OS_TYPE          OS Type - OL76/OL74/OL73/RHEL76
    -jdkversion           JDK_VERSION      JDK VERSION - JDK8/JDK11
   [-validationonly       VALIDATION_ONLY  true/false - If set to true runs only validation. default value is false ]
    -h|?|--help           HELP             Help/Usage info
USAGE

exit 1

}

get_param()
{
    while [ "$1" ]
    do
        case $1 in    
       -h |?|--help )  usage ;;
          -rgprefix )  RG_PREFIX=$2 ;;
         -offertype )  OFFER_TYPE=$2 ;;
        -wlsversion )  WLS_VERSION=$2;;
            -ostype )  OS_TYPE=$2 ;;
        -jdkversion )  JDK_VERSION=$2 ;;
     -validationonly)  VALIDATION_ONLY=$2;;
                   *)  echo 'invalid arguments specified'
                       usage;;
        esac
        shift 2
    done
}

validate_input()
{
    if [ -z "$RG_PREFIX" ];
    then
     echo "Error !! Resource Group Prefix is empty"
     exit 1
    fi

    if [ -z "$OFFER_TYPE" ];
    then
     echo "Error !! Offer Type is empty"
     exit 1
    fi
    
    if [ -z "$WLS_VERSION" ];
    then
     echo "Error !! WebLogic Version is empty."
     exit 1
    fi
  
    if [ -z "$OS_TYPE" ];
    then
     echo "Error !! OS_TYPE is empty."
     exit 1
    fi

    if [ -z "$JDK_VERSION" ];
    then
     echo "Error !! JDK VERSION is empty."
     exit 1
    fi

    if [ -z "$VALIDATION_ONLY" ];
    then
     echo "VALIDATION_ONLY flag is empty. So setting it to false."
     VALIDATION_ONLY="false"
    fi
}

#main

if [ "$#" -lt "10" ];
then
 usage;
fi

get_param "$@"
validate_input

RUN_ID=$(date +"%Y%m%d%H%M%S")
OS_TYPE_LC="${OS_TYPE,,}"
JDK_VERSION_LC="${JDK_VERSION,,}"
RUN_PREFIX="${RG_PREFIX}_${OFFER_TYPE}_${OS_TYPE_LC}_${WLS_VERSION}_${JDK_VERSION_LC}"
MAIN_TEMPLATE_RUN_FILE="${RUN_DIR}/${RUN_PREFIX}_main_run.json"

getParameterFile

setupTemplate ${OFFER_TYPE} ${MAIN_TEMPLATE_RUN_FILE}
RG_NAME="$(getRGName ${RUN_PREFIX} ${RUN_ID})"

setupRG "${RG_NAME}"

validateTemplate ${RG_NAME} ${MAIN_TEMPLATE_RUN_FILE} ${PARAM_FILE}

if [ "$VALIDATION_ONLY" == "true" ];
then
  echo "Validation Only Flag is set to true. So, skipping deployment"
  echo "Cleaning up resource group ${RG_NAME} used for template validation"
  cleanupRG ${RG_NAME}
  exit 0
fi

deployTemplate ${RG_NAME} ${MAIN_TEMPLATE_RUN_FILE} ${PARAM_FILE}

VM_PUBLIC_IP=$(getVMPublicIP)

createNSGRuleWithInternetAccess "$RG_NAME"
sleep 1m

VM_IP_IFCONFIG="$(getVMPublicIPUsingIfconfig)"

echo "VM_IP_CONFIG: $VM_IP_IFCONFIG"
echo "VM_PUBLIC_IP: $VM_PUBLIC_IP"

if [ "$VM_IP_IFCONFIG" == "$VM_PUBLIC_IP" ];
then
  echo "VM configuration is successful and accessible via SSH"
else
  echo "VM configuration failed. Please verify the logs and try again !!"
  exit 1
fi
