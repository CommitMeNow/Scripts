#This Azure bash script will deploy an AKS cluster using workload identity
#
#PreReqs: keyvault must exist prior to script run with proper permissions
#

#Setup Repeating Variables
export RG_NAME="RG-AKSWorkloadIdentityDeployment"
export LOCATION="westus"
export USER_ASSIGNED_IDENTITY_NAME="myAKSLabIdentity"
export AKS_NAME="aksCluster"

#Create Resource Group
az group create --name "${RG_NAME}" --location "${LOCATION}"

#Create the OIDC workload enabled cluster
az aks create -g "${RG_NAME}" -n "${AKS_NAME}" --node-count 1 --enable-oidc-issuer --enable-workload-identity --generate-ssh-keys

#Get OIDC Issuer URL and save to environment variable
export AKS_OIDC_ISSUER="$(az aks show -n "${AKS_NAME}" -g "${RG_NAME}" --query "oidcIssuerProfile.issuerUrl" -otsv)"

#Create MI and grant permissions to access Azure Key Vault
export SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RG_NAME}" --location "${LOCATION}" --subscription "${SUBSCRIPTION_ID}"

#Grant access to an existing key vault
export KEYVAULT_NAME="kv-SharedServices01" #THIS MUST EXIST PRIOR TO SCRIPT RUN
export USER_ASSIGNED_CLIENT_ID="$(az identity show --resource-group "${RG_NAME}" --name "${USER_ASSIGNED_IDENTITY_NAME}" --query 'clientId' -otsv)"
az keyvault set-policy --name "${KEYVAULT_NAME}" --secret-permissions get --spn "${USER_ASSIGNED_CLIENT_ID}"  #applies ONLY the GET permission

#Create AKS service account
az aks get-credentials -n "${AKS_NAME}" -g "${RG_NAME}"

export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SERVICE_ACCOUNT_NAMESPACE="default"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: "${USER_ASSIGNED_CLIENT_ID}"
  labels:
    azure.workload.identity/use: "true"
  name: "${SERVICE_ACCOUNT_NAME}"
  namespace: "${SERVICE_ACCOUNT_NAMESPACE}"
EOF

az identity federated-credential create --name myfederatedIdentity --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RG_NAME}" --issuer "${AKS_OIDC_ISSUER}" --subject system:serviceaccount:"${SERVICE_ACCOUNT_NAMESPACE}":"${SERVICE_ACCOUNT_NAME}"