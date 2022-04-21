# Update exoisting AKS
az aks enable-addons --addons azure-keyvault-secrets-provider \
    -n $AKS_NAME \
    -g $RG_NAME

# Verify the Azure Key Vault Provider for Secrets Store CSI Driver installation
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'


# Generate certificate and import to AKV
#######################
# Generate .crt and .key files
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out $CERT_NAME.crt \
    -keyout $CERT_NAME.key \
    -subj "/CN=demo /O=tls"

# Convert certificate to .pfx file
openssl pkcs12 -export \
    -in $CERT_NAME.crt \
    -inkey $CERT_NAME.key \
    -out $CERT_NAME.pfx
# skip Password prompt


# Create KeyVault
az keyvault create -n $AKV_NAME -g $RG_NAME -l $LOC_NAME

#Import the certificate to AKV
az keyvault certificate import --vault-name $AKV_NAME -n $CERT_NAME -f $CERT_NAME.pfx



# Deploy a SecretProviderClass
##############################
kubectl create ns $NS_NAME

# Use pod identities
####################
# Register the EnablePodIdentityPreview
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService

# Install the aks-preview Azure CLI
az extension add --name aks-preview

# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview

# Update an existing AKS cluster with Kubenet network plugin
az aks update -g $RG_NAME -n $AKS_NAME --enable-pod-identity --enable-pod-identity-with-kubenet

# Create an identity
export IDENTITY_RESOURCE_GROUP=$RG_NAME
export IDENTITY_NAME="csi-app-identity"
az identity create -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME}
export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"
# Assign permissions for the managed identity
export NODE_GROUP=$(az aks show -g $RG_NAME -n $AKS_NAME --query nodeResourceGroup -o tsv)
export NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")
az role assignment create --role "Virtual Machine Contributor" --assignee "$IDENTITY_CLIENT_ID" --scope $NODES_RESOURCE_ID

# Create a pod identity
export POD_IDENTITY_NAME="csi-app-identity"
export POD_IDENTITY_NAMESPACE=$NS_NAME
az aks pod-identity add -g $RG_NAME --cluster-name $AKS_NAME \
                        --namespace ${POD_IDENTITY_NAMESPACE} \
                        --name ${POD_IDENTITY_NAME} \
                        --identity-resource-id ${IDENTITY_RESOURCE_ID}

# Check identity resources
kubectl get azureidentity -n $POD_IDENTITY_NAMESPACE
kubectl get azureidentitybinding -n $POD_IDENTITY_NAMESPACE



# set policy to access keys in your key vault
# az keyvault set-policy -n $AKV_NAME --key-permissions get --spn $IDENTITY_CLIENT_ID
# set policy to access secrets in your key vault
# az keyvault set-policy -n $AKV_NAME --secret-permissions get --spn $IDENTITY_CLIENT_ID
# set policy to access certs in your key vault
az keyvault set-policy -n $AKV_NAME --certificate-permissions get --spn $IDENTITY_CLIENT_ID

# Create SecretProviderClass.yaml
vi SecretProviderClass.yaml
## <a> + copy file content in SecretProviderClass.yaml + <ESC> + <:wq>
kubectl apply -f SecretProviderClass.yaml


# Create csi-front-pod.yaml
vi csi-front-pod.yaml
# <a> + copy file content in csi-front-pod.yaml + <ESC> + <:wq>
kubectl delete -f front-pod.yaml
kubectl get pods
kubectl apply -f csi-front-pod.yaml

## Check app runing
#kubectl logs azure-frontend --follow --namespace $POD_IDENTITY_NAMESPACE



curl -X POST 'https://login.microsoftonline.com/b41b72d0-4e9f-4c26-8a69-f949f367c91d/oauth2/v2.0/token' -d 'grant_type=client_credentials&client_id="andrei krupen"&client_secret=com8Gmail&scope=https://vault.azure.net/.default'