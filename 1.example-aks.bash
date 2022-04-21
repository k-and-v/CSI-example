# Run the Azure CLI in a Docker container
docker run -it mcr.microsoft.com/azure-cli

# Sign into the Azure CLI
az login                        # singing in browser on Azure sing-page
# If NO browser
az login --use-device-code      # singing in browser on the othe device with device-code


# Verify Microsoft.OperationsManagement and Microsoft.OperationalInsights are registered on your subscription.
az provider show -n Microsoft.OperationsManagement -o table
az provider show -n Microsoft.OperationalInsights -o table

# If they are NOT registered:
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights

# Variable section:
export RG_NAME=rg-csitest                                   # resource groupe name
export LOC_NAME=westeurope                                  # location name
export AKV_NAME=akv-csi5343                                 # KeyVault name
export AKS_NAME=aks-csitest                                 # AKS name
export SUB_NAME="c20af893-07e7-4184-98c7-efaf39fe8981"      # subscription ID
export CERT_NAME=crt-csiname                                # certificate name
export NS_NAME=ns-csitest                                   # namespace in AKS

# Create a resource group
az group create -n $RG_NAME -l $LOC_NAME


# Create AKS cluster
az aks create -g $RG_NAME -n $AKS_NAME \
              --node-count 1 \
              --enable-addons monitoring \
              --generate-ssh-keys

# Connect to the cluster:
# Install kubectl locally
az aks install-cli
# Downloads credentials and configures the Kubernetes CLI
az aks get-credentials -g $RG_NAME -n $AKS_NAME
# Verify the connection to cluster
kubectl get nodes
# VIEW EXAMPLE:
#-> NAME                                STATUS   ROLES   AGE     VERSION
#-> aks-nodepool1-10054480-vmss000000   Ready    agent   3m40s   v1.21.9

# Create back-deploy.yaml
vi back-deploy.yaml
# <a> + copy file content in back-deploy.yaml + <ESC> + <:wq>
# Create back-service.yaml
vi back-service.yaml
# <a> + copy file content in back-service.yaml + <ESC> + <:wq>
# Create front-pod.yaml
vi front-pod.yaml
# <a> + copy file content in front-pod.yaml + <ESC> + <:wq>
# Create front-service.yaml
vi front-service.yaml
# <a> + copy file content in front-service.yaml + <ESC> + <:wq>


# Deploy the backend of application
kubectl apply -f back-pod.yaml
kubectl apply -f back-service.yaml
# Deploy the frontend of application
kubectl apply -f front-pod.yaml
kubectl apply -f front-service.yaml

# Test the application
kubectl get service azure-frontend --watch
# VIEW EXAMPLE:
#-> NAME             TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
#-> azure-frontend   LoadBalancer   10.0.128.134   20.101.165.171   80:32397/TCP   56s

# Open in browser
<EXTERNAL-IP>:<PORT>
