# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Deploy Azure Key Vault Provider for Secrets Store CSI Driver
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure
# helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace kube-system

# Create Keyvault and set secrets
az group create -n ${AKV_RESOURCE_GROUP} --location ${AKV_LOCATION}
az keyvault create -n ${AKV_NAME} -g ${AKV_RESOURCE_GROUP} --location ${AKV_LOCATION}

az keyvault secret set --vault-name ${AKV_NAME} --name secret1 --value "Hello\!"

# Create an identity on Azure and set access policies
# Create a service principal to access keyvault
export SERVICE_PRINCIPAL_CLIENT_SECRET="$(az ad sp create-for-rbac --skip-assignment --name http://akv-csi-zljgfk7pdd --query 'password' -otsv)"
export SERVICE_PRINCIPAL_CLIENT_ID="$(az ad sp show --id http://akv-csi-zljgfk7pdd --query 'appId' -otsv)"


