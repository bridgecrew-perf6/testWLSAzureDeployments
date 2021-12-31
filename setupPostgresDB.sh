#/!bin/bash



RG_NAME="wlspostgresqldb_rg"
DB_USER="weblogic"
DB_PASSWORD="Gumby12340987"
LOCATION="eastus"
DB_NAME="wlspostgresqldb"

echo "creating resource group for setting up PostgreSQL DB"
az group create --location ${LOCATION} --name ${RG_NAME}

azCommand="az postgres server create --resource-group ${RG_NAME} --name ${DB_NAME} --admin-password ${DB_PASSWORD} --sku-name B_Gen5_1 --location ${LOCATION} --admin-user ${DB_USER} --ssl-enforcement Disabled --public-network-access Enabled"

echo "Executing Azure Command: $azCommand"

eval $azCommand

if [ $? == 0 ];
then
  echo "PostgreSQL DB setup successfully"
  echo "Enabling access to Azure PostgreSQL DB to Azure VMs"
  az postgres server firewall-rule create --resource-group ${RG_NAME} --server-name ${DB_NAME} -n allowaccesstoazurevms --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
else
  echo "Failed to setup PostgreSQL DB. Please check the logs and retry."
  exit 1
fi





