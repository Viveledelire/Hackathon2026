# Hackathon2026

## Get kubeconfig

```bash
tofu output -show-sensitive -raw kube_config > ~/.kube/config
```

## Login to AKS Cluster

You can use `kubectl` to interact with your AKS cluster. First, authenticate with Azure and get the AKS credentials:

```bash
az login                          # Log in to your Azure account
az account set --subscription <your-subscription>  # Set the appropriate subscription
az aks get-credentials --name <aks-cluster-name> --resource-group <resource-group-name>
```

## Login to ACR Registry

```bash
az acr login --name <acr-name>
docker push <acr-name>.azurecr.io/<image-name>:<tag>
```
