#!/bin/bash

function setProxy()
{
    export HTTP_PROXY=http://www-proxy-hqdc.us.oracle.com:80
    export http_proxy=http://www-proxy-hqdc.us.oracle.com:80
    export HTTPS_PROXY=http://www-proxy-hqdc.us.oracle.com:80
    export https_proxy=http://www-proxy-hqdc.us.oracle.com:80
    export NO_PROXY=localhost,127.0.0.1,.us.oracle.com,.oraclecorp.com,.oraclevcn.com
    export no_proxy=localhost,127.0.0.1,.us.oracle.com,.oraclecorp.com,.oraclevcn.com
}

function getParameterFile()
{
    OS_TYPE_LC="${OS_TYPE,,}"
    JDK_VERSION_LC="${JDK_VERSION,,}"

    PARAM_FILE_NAME="${OFFER_TYPE}_${OS_TYPE_LC}_${WLS_VERSION}_${JDK_VERSION_LC}.json"
    PARAM_FILE="${PARAM_FILES_DIR}/${PARAM_FILE_NAME}"

    if [ -f "${PARAM_FILE}" ];
    then
      echo "Valid Parameter File found: ${PARAM_FILE}"
    else
      echo "Error !! Unable to retrieve Parameters File: ${PARAM_FILE}. Please check input provided and try again"
      exit 1
    fi
}

function getRGName()
{
  local RG_PREFIX="$1"
  local RG_SUFFIX="$2"
  local RG_NAME="${RG_PREFIX}_${RG_SUFFIX}"
  echo "${RG_NAME}"
}

function setupRG()
{
   RG_NAME="$1"
   mkdir -p ${SCRIPT_DIR}/run 
   echo "creating resource group with name $RG_NAME"
   az group create --location ${LOCATION} --name ${RG_NAME}

   if [ $? == 0 ];
   then
       echo "${RG_NAME}"
   else
       echo "Error while creating Resource Group: ${RG_NAME}"
       exit 1
   fi
}

function cleanupRG()
{
  local RG_NAME="$1"
  az group delete --resource-group $RG_NAME --yes --no-wait
}

function setupTemplate()
{
   local OFFER_TYPE="$1"
   local MAIN_TEMPLATE_RUN_FILE="$2"

   ARM_TEMPLATE_URL=$(getTemplateURLForOffer "$1")

   echo "ARM_TEMPLATE_URL : ${ARM_TEMPLATE_URL}"

   wget --quiet $ARM_TEMPLATE_URL
   local MAIN_TEMPLATE="${ARM_TEMPLATE_URL##*/}"
   mv $MAIN_TEMPLATE ${MAIN_TEMPLATE_RUN_FILE}
   preprocessTemplate ${MAIN_TEMPLATE_RUN_FILE}
}

function getTemplateURLForOffer()
{
   local OFFER_TYPE="$1"

   if [ "$OFFER_TYPE" == "singlenode" ];
   then
     echo "${SINGLE_NODE_MAIN_TEMPLATE}"
   elif  [ "$OFFER_TYPE" == "admin" ];
   then
     echo "${ADMIN_MAIN_TEMPLATE}"
   elif [ "$OFFER_TYPE" == "cluster" ];
   then
     echo "${CLUSTER_MAIN_TEMPLATE}"
   elif [ "$OFFER_TYPE" == "dynamiccluster" ];
   then
     echo "${DYNAMIC_CLUSTER_MAIN_TEMPLATE}"
   else
     echo "Invalid Offer Type"
   fi
}

function preprocessTemplate()
{

     echo "preprocessing template before deployment.."

     local TEMPLATE_FILE="$1"

     sed -i 's|${start}|b446fe15-5d43-5549-858d-4775741cd0ba|g' $TEMPLATE_FILE
     sed -i 's|${end}|pid-a63dea86-f8db-4e75-a231-1145d4f3ab6e-partnercenter|g' $TEMPLATE_FILE
 
     sed -i 's|${azure.apiVersion}|2020-06-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersion2}|2019-06-01|g' $TEMPLATE_FILE
     sed -i 's|${database.oracle}|pid-692b2d84-72f5-5992-a15d-0d5bcfef040d|g' $TEMPLATE_FILE
     sed -i 's|${database.postgresql}|pid-935df06e-a5d5-5bf1-af66-4c1eb71dac7a|g' $TEMPLATE_FILE
     sed -i 's|${database.sqlserver}|pid-3569588c-b89d-5567-84ee-a2c633c7204c|g' $TEMPLATE_FILE
     sed -i 's|${admin.aad.end}|pid-6449f9a2-0713-5a81-a886-dce6d8d5c137|g' $TEMPLATE_FILE
     sed -i 's|${admin.aad.start}|6245e080-ab9b-5e42-ac14-fc38cc610a11|g' $TEMPLATE_FILE
     sed -i 's|${admin.admin.start}|pid-88e1c590-988c-51bb-bbd3-4929629bfb9c|g' $TEMPLATE_FILE
     sed -i 's|${admin.database.end}|pid-4a2ba562-fbca-552d-9f02-51e88844a911|g' $TEMPLATE_FILE
     sed -i 's|${admin.database.start}|pid-f5215b75-9465-51b6-9b1d-69bc41e3e6f4|g' $TEMPLATE_FILE
     sed -i 's|${admin.end}|pid-40a6f402-31ee-536a-a006-729105f55003|g' $TEMPLATE_FILE
     sed -i 's|${admin.start}|pid-07bf10d5-da4e-5113-b1c2-b8d802bda651|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122130-jdk8-ol74}|pid-caa3ea2b-cdec-55ee-8510-854ed10d7ebe|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122130-jdk8-ol73}|pid-bf1d0f1a-cb9a-5453-bf70-42b4efe8c15e|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122140-jdk8-ol76}|pid-bde756bb-ce96-54d5-a478-04d9bd87e9db|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk8-ol76}|pid-b6f00a34-1478-5a10-9a84-49c4051b57b8|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk11-ol76}|pid-afc8f9c5-8c5d-5d1b-ab4d-3116ca908bfd|g' $TEMPLATE_FILE

     sed -i 's|${from.owls-122140-jdk8-rhel76}|0a52f317-8b40-4a77-9f3c-7607fc3ebfb7wls|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk8-rhel76}|26ec5cf5-dd84-4764-97cf-4f830facbf66wls|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk11-rhel76}|ada2e3e6-faef-4339-aaac-40bcdc4484ecwls|g' $TEMPLATE_FILE


     sed -i 's|${admin.admin.end}|admin.admin.end|g' $TEMPLATE_FILE
     sed -i 's|${cluster.dns.start}|cluster.dns.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.dns.end}|cluster.dns.end|g' $TEMPLATE_FILE
     sed -i 's|${admin.elk.start}|admin.elk.start|g' $TEMPLATE_FILE
     sed -i 's|${admin.elk.end}|admin.elk.end|g' $TEMPLATE_FILE

     sed -i 's|${azure.apiVersionForDeploymentScript}|2020-10-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDNSZone}|2018-05-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForKeyVault}|2019-09-01|g' $TEMPLATE_FILE

     sed -i 's|${post.deploy.ssl.config.start}|post.deploy.ssl.config.start|g' $TEMPLATE_FILE
     sed -i 's|${post.deploy.ssl.config.end}|post.deploy.ssl.config.end|g' $TEMPLATE_FILE

     sed -i 's|${azure.apiVersion}|2020-06-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersion2}|2019-06-01|g' $TEMPLATE_FILE
     sed -i 's|${database.oracle}|pid-692b2d84-72f5-5992-a15d-0d5bcfef040d|g' $TEMPLATE_FILE
     sed -i 's|${database.postgresql}|pid-935df06e-a5d5-5bf1-af66-4c1eb71dac7a|g' $TEMPLATE_FILE
     sed -i 's|${database.sqlserver}|pid-3569588c-b89d-5567-84ee-a2c633c7204c|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.aad.end}|pid-6449f9a2-0713-5a81-a886-dce6d8d5c137|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.aad.start}|6245e080-ab9b-5e42-ac14-fc38cc610a11|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.cluster.end}|pid-eedac070-39c0-5947-a4d7-cfc864417b49|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.cluster.start}|pid-88e1c590-988c-51bb-bbd3-4929629bfb9c|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.database.end}|pid-4a2ba562-fbca-552d-9f02-51e88844a911|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.database.start}|pid-f5215b75-9465-51b6-9b1d-69bc41e3e6f4|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.end}|pid-93da13bf-11f6-5bfb-9b51-7deb152a21c3|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.start}|pid-2551958c-2465-5e2e-8e28-0b3a4babf3f0|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122130-jdk8-ol74}|pid-caa3ea2b-cdec-55ee-8510-854ed10d7ebe|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122130-jdk8-ol73}|pid-bf1d0f1a-cb9a-5453-bf70-42b4efe8c15e|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122140-jdk8-ol76}|pid-bde756bb-ce96-54d5-a478-04d9bd87e9db|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk8-ol76}|pid-b6f00a34-1478-5a10-9a84-49c4051b57b8|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk11-ol76}|pid-afc8f9c5-8c5d-5d1b-ab4d-3116ca908bfd|g' $TEMPLATE_FILE
     sed -i 's|${cluster.dns.start}|cluster.dns.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.dns.end}|cluster.dns.end|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.coherence.start}|pid-22e98104-2229-5ec7-9a90-12edca3d88e7|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.coherence.end}|pid-157ea51e-12ae-11eb-adc1-0242ac120002|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.elk.start}|pid-bc636673-2dca-5e40-a2aa-6891c344aa17|g' $TEMPLATE_FILE
     sed -i 's|${dynamic.elk.end}|pid-d154e480-15e2-5cf7-bdd5-6219c1793967|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDeploymentScript}|2020-10-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDNSZone}|2018-05-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForKeyVault}|2019-09-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForIndentity}|2018-11-30|g' $TEMPLATE_FILE

     sed -i 's|${from.owls-122140-jdk8-rhel76}|0a52f317-8b40-4a77-9f3c-7607fc3ebfb7wls|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk8-rhel76}|26ec5cf5-dd84-4764-97cf-4f830facbf66wls|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk11-rhel76}|ada2e3e6-faef-4339-aaac-40bcdc4484ecwls|g' $TEMPLATE_FILE

     sed -i 's|${azure.apiVersion}|2020-06-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersion2}|2019-06-01|g' $TEMPLATE_FILE
     sed -i 's|${cluster.aad.end}|pid-6449f9a2-0713-5a81-a886-dce6d8d5c137|g' $TEMPLATE_FILE
     sed -i 's|${cluster.aad.start}|6245e080-ab9b-5e42-ac14-fc38cc610a11|g' $TEMPLATE_FILE
     sed -i 's|${cluster.cluster.end}|pid-eedac070-39c0-5947-a4d7-cfc864417b49|g' $TEMPLATE_FILE
     sed -i 's|${cluster.cluster.start}|pid-88e1c590-988c-51bb-bbd3-4929629bfb9c|g' $TEMPLATE_FILE
     sed -i 's|${cluster.database.end}|pid-4a2ba562-fbca-552d-9f02-51e88844a911|g' $TEMPLATE_FILE
     sed -i 's|${cluster.database.start}|pid-f5215b75-9465-51b6-9b1d-69bc41e3e6f4|g' $TEMPLATE_FILE
     sed -i 's|${cluster.end}|pid-93da13bf-11f6-5bfb-9b51-7deb152a21c3|g' $TEMPLATE_FILE
     sed -i 's|${cluster.start}|pid-2551958c-2465-5e2e-8e28-0b3a4babf3f0|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122130-jdk8-ol74}|pid-caa3ea2b-cdec-55ee-8510-854ed10d7ebe|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122130-jdk8-ol73}|pid-bf1d0f1a-cb9a-5453-bf70-42b4efe8c15e|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-122140-jdk8-ol76}|pid-bde756bb-ce96-54d5-a478-04d9bd87e9db|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk8-ol76}|pid-b6f00a34-1478-5a10-9a84-49c4051b57b8|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk11-ol76}|pid-afc8f9c5-8c5d-5d1b-ab4d-3116ca908bfd|g' $TEMPLATE_FILE
     sed -i 's|${cluster.dns.start}|cluster.dns.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.dns.end}|cluster.dns.end|g' $TEMPLATE_FILE
     sed -i 's|${cluster.coherence.start}|pid-22e98104-2229-5ec7-9a90-12edca3d88e7|g' $TEMPLATE_FILE
     sed -i 's|${cluster.coherence.end}|pid-157ea51e-12ae-11eb-adc1-0242ac120002|g' $TEMPLATE_FILE
     sed -i 's|${cluster.elk.start}|pid-bc636673-2dca-5e40-a2aa-6891c344aa17|g' $TEMPLATE_FILE
     sed -i 's|${cluster.elk.end}|pid-d154e480-15e2-5cf7-bdd5-6219c1793967|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDeploymentScript}|2020-10-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDNSZone}|2018-05-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForKeyVault}|2019-09-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForIndentity}|2018-11-30|g' $TEMPLATE_FILE
     sed -i 's|${cluster.appgateway.start}|cluster.appgateway.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.appgateway.end}|cluster.appgateway.end|g' $TEMPLATE_FILE
     sed -i 's|${cluster.aad.start}|cluster.add.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.coherence.start}|cluster.coherence.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.coherence.end}|cluster.coherence.end|g' $TEMPLATE_FILE
     sed -i 's|${cluster.appgateway.keyvault.start}|cluster.appgateway.keyvault.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.appgateway.keyvault.end}|cluster.appgateway.keyvault.end|g' $TEMPLATE_FILE
     sed -i 's|${cluster.elk.start}|admin.elk.start|g' $TEMPLATE_FILE
     sed -i 's|${cluster.elk.end}|admin.elk.end|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDeploymentScript}|2020-10-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForDNSZone}|2018-05-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForKeyVault}|2019-09-01|g' $TEMPLATE_FILE
     sed -i 's|${azure.apiVersionForIndentity}|2018-11-30|g' $TEMPLATE_FILE
     sed -i 's|${database.oracle}|pid-692b2d84-72f5-5992-a15d-0d5bcfef040d|g' $TEMPLATE_FILE
     sed -i 's|${database.postgresql}|pid-935df06e-a5d5-5bf1-af66-4c1eb71dac7a|g' $TEMPLATE_FILE
     sed -i 's|${database.sqlserver}|pid-3569588c-b89d-5567-84ee-a2c633c7204c|g' $TEMPLATE_FILE

     sed -i 's|${from.owls-122140-jdk8-rhel76}|0a52f317-8b40-4a77-9f3c-7607fc3ebfb7wls|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk8-rhel76}|26ec5cf5-dd84-4764-97cf-4f830facbf66wls|g' $TEMPLATE_FILE
     sed -i 's|${from.owls-141100-jdk11-rhel76}|ada2e3e6-faef-4339-aaac-40bcdc4484ecwls|g' $TEMPLATE_FILE

     #cat $TEMPLATE_FILE

     echo "template preprocessing complete."
}

function validateTemplate()
{
   local RG_NAME="$1"
   local MAIN_TEMPLATE_RUN_FILE="$2"
   local PARAMS_FILE="$3"

   local artificatsLocation="$(getArtifactLocation)"

   azCommand="az deployment group validate --resource-group ${RG_NAME} --template-file ${MAIN_TEMPLATE_RUN_FILE} --parameters ${PARAMS_FILE} --parameters _artifactsLocation=${artificatsLocation}"
   echo "Running Azure Command: $azCommand"

   eval $azCommand

   if [ $? == 0 ];
   then
       echo "Template Validation Completed successfully"
   else
       echo "Error while validating template-file ${MAIN_TEMPLATE_RUN_FILE} for Resource Group: ${RG_NAME} for parameters file:  ${PARAMS_FILE}"
       exit 1
   fi
}

function getArtifactLocation()
{
   if [ "$OFFER_TYPE" == "singlenode" ];
   then
     echo "${SINGLE_NODE_ARTIFACT_LOCATION}"
   elif  [ "$OFFER_TYPE" == "admin" ];
   then
     echo "${ADMIN_ARTIFACT_LOCATION}"
   elif [ "$OFFER_TYPE" == "cluster" ];
   then
     echo "${CLUSTER_ARTIFACT_LOCATION}"
   elif [ "$OFFER_TYPE" == "dynamiccluster" ];
   then
     echo "${DYNAMIC_CLUSTER_ARTIFACT_LOCATION}"
   else
     echo "Invalid Offer Type"
   fi
}

function deployTemplate()
{
   local RG_NAME="$1"
   local MAIN_TEMPLATE_RUN_FILE="$2"
   local PARAMS_FILE="$3"

   local artificatsLocation="$(getArtifactLocation)"

   azCommand="az deployment group create --resource-group ${RG_NAME} --template-file ${MAIN_TEMPLATE_RUN_FILE} --parameters ${PARAMS_FILE} --parameters _artifactsLocation=${artificatsLocation}"
   echo "Running Azure Command: $azCommand"

   eval $azCommand

   if [ $? == 0 ];
   then
       echo "Deployment Completed successfully"
   else
       echo "Error while deployment template-file ${MAIN_TEMPLATE_RUN_FILE} for Resource Group: ${RG_NAME} for parameters file:  ${PARAMS_FILE}"
       exit 1
   fi
}

function createNSGRuleWithInternetAccess()
{
  local RG_NAME="$1"

  az network nsg rule create -g $RG_NAME --nsg-name $NSG_NAME  -n $SSH_ACCESS_INTERNET  --priority $SSH_ACCESS_INTERNET_PRIORITY --source-address-prefixes Internet --destination-port-ranges 22   --destination-address-prefixes '*' --access Allow --protocol Tcp --description "Allow SSH access to Internet on port 22."
}

function deleteNSGRuleWithInternetAccess()
{
  local RG_NAME="$1"
  az network nsg rule delete -g $RG_NAME --nsg-name $NSG_NAME  -n $SSH_ACCESS_INTERNET
}

function createNSGRuleWithClientSpecificAccess()
{
  local RG_NAME="$1"
  local CLIENT_IP="$2"

  az network nsg rule create -g $RG_NAME --nsg-name $NSG_NAME  -n $SSH_ACCESS_IP_SPECIFIC  --priority $SSH_ACCESS_IP_SPECIFIC_PRIORITY --source-address-prefixes $CLIENT_IP --destination-port-ranges 22   --destination-address-prefixes '*' --access Allow --protocol Tcp --description "Allow SSH access to CIDR on port 22."
}

function executeSSHPassCmd()
{
   local VM_IP="$1"
   local COMMAND="$2"

   local OUTPUT=$(sshpass -p "$VM_PASSWORD" ssh -o StrictHostKeyChecking=no ${VM_USERNAME}@${VM_IP} "${COMMAND}")
   echo "$OUTPUT"
}

function installWhoIsUtility()
{
  local VM_IP="$1"
  executeSSHPassCmd "$VM_IP" "sudo -S <<< $VM_PASSWORD yum install -y whois"
}

function getVMPublicIP()
{
  
  if [ "$OFFER_TYPE" == "singlenode" ];
  then
    VM_NAME="${SINGLE_NODE_VM_NAME}"
  else
    VM_NAME="${DOMAIN_OFFER_VM_NAME}"
  fi

  VM_PUBLIC_IP=$(az vm show -d -g $RG_NAME -n $VM_NAME --query publicIps -o tsv)
  echo "$VM_PUBLIC_IP"
}

function getVMPublicIPUsingIfconfig()
{
  VM_IP_IFCONFIG=$(executeSSHPassCmd "$VM_PUBLIC_IP" "curl -L -s ifconfig.me")
  echo "$VM_IP_IFCONFIG"
}

#main

UTILS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $UTILS_DIR/config.properties
setProxy