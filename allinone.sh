#!/bin/bash

GROUPNAME=""
LOCATION=""
AKSNAME=""
ACRNAME="acrdemo$RANDOM" # must be globally unique


### get version by running
### az aks get-versions --location $LOCATION --output table
k8sversion="1.19.7"

# create rbac username and password
az  ad sp create-for-rbac --skip-assignment -o yaml > temp

sleep 5


APPID=$(grep appId temp | awk '{ print $2;}')
PASS=$(grep password temp | awk '{ print $2;}')

echo $APPID
echo $PASS

sleep 5

# create resource group based on groupname variable
az group create --name $GROUPNAME --location $LOCATION 

sleep 2

# create aks cluster

echo "Creating cluster, this could take a few mins"

az aks create --resource-group $GROUPNAME --name $AKSNAME \
--enable-addons monitoring,http_application_routing \
--kubernetes-version $k8sversion  --generate-ssh-keys \
--service-principal $APPID --client-secret $PASS \
--node-count 1

# get the aks cluster pass for kubectl access

az aks get-credentials --resource-group $GROUPNAME --n $AKSNAME

echo "cluster creds for are imported"

# create an azure container registry for images, admin enabled for docker login

az acr create --resource-group $GROUPNAME --name $ACRNAME --sku Standard --admin-enabled true

echo "your cluster is now ready to use, check the portal for more details"

kubectl get nodes
cat temp
echo "Keep these credentials for future use"

rm temp

kubectl apply -f https://gist.githubusercontent.com/AnaMMedina21/d45fe777b4db356d271c0d9b229978f7/raw/cbb821037be75ff9ca7aed4d049b324e7f77be5f/boutique-shop.yaml
