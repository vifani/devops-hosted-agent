# Introduction
This repository contains resources to build a Docker image containing Visual Studio Build Tools and an Azure DevOps Agent. This image can be used to deploy a **self-hosted Windows Azure DevOps Build agent**.

# Build and run a Docker image on Windows
In order to build the container image on Windows you need to 
- Install Docker Desktop (https://www.docker.com/products/docker-desktop)
- Switch to Windows Containers

Then you are ready to build the image with the following steps:

- Clone the repository
```
git clone https://github.com/vifani/devops-hosted-agent.git
```
- Build the image
```
docker build -t windows-build-agent:latest .
```
- Run the image
```
docker run -e AZP_URL=<Azure DevOps instance> -e AZP_TOKEN=<PAT token> -e AZP_POOL=<Pool Name> -e AZP_AGENT_NAME=mydockeragent windows-build-agent:latest
```

Parameters:
- AZP_URL: for example "https://dev.azure.com/yourorganization"
- AZP_TOKEN: a valid Personal Access Token (see https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page)
- AZP_POOL: the Azure DevOps Agent Pool name (you can manage them in Azure DevOps from Project Settings -> Agent pools, see https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops&tabs=yaml%2Cbrowser)
- AZP_AGENT_NAME: the agent name

<br>

# Build Docker Image on Azure Container Registry
If you don't want to use or install locally Docker Desktop, you can use Azure Container Registry to build a container image.

In this case the steps are the following:
- Install Azure CLI (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Clone the repository
```
git clone https://github.com/vifani/devops-hosted-agent.git
```
- Login to Azure
```
az login
```
- Create a Resource Group and an Azure Container Registry instance
```
az group create --name devopsagent --location westeurope
az acr create --resource-group devopsagent --name acrvifani --sku Basic --admin-enabled true
```
- Build the image
```
az acr build --registry acrvifani -t windows-build-agent:v1.0 --platform windows .
```
After the build you can use the hosting you prefer to run the container image: Azure Kubernetes Service, Azure Container Instance or Web App for Containers

# Run a Docker Image on Azure Web App for Containers
Azure Web App for Containers is one way to run a container on Azure. Basically it uses a configuration for an App Service in order to run a container based on Linux or Windows. 
The minimal resource set that we need are: a Container Registry, an Azure App Service Plan supporting containers and a Web App for Containers instance.
Considering that in the previous chapter we have already set up an Azure Container Registry, the steps to prepare the remaining resources are the following:
```
az appservice plan create -g devopsagent -n appservplandevopsagent --hyper-v --sku P1V3
az webapp create -g devopsagent -p appservplandevopsagent -n appservicedevopsagent -i acrvifani.azurecr.io/windows-build-agent:v1.0 --docker-registry-server-user <<some user name>> --docker-registry-server-password <<some password>>
```

Because we are running an Azure DevOps Agent on Windows, we have to use at least the P1V3 SKU, the minimal supporting Hyper-V (you can see the --hyper-v flag in the CLI command).

The last step is about configuring our DevOps Agent. We need to put into the App Service Settings the same parameters we have used to run the Docker Image locally on Windows. We can use the following command to define the settings:
```
az webapp config appsettings set -g devopsagent -n appservicedevopsagent --settings AZP_URL=<Azure DevOps instance> AZP_TOKEN=<PAT token> AZP_POOL=<Pool Name> AZP_AGENT_NAME=mydockeragent
```

By default, all Windows Containers deployed in Azure App Service are limited to 1 GB RAM. If you need more memory, you can change this value by providing the WEBSITE_MEMORY_LIMIT_MB app setting
```
az webapp config appsettings set -g devopsagent -n appservicedevopsagent --settings WEBSITE_MEMORY_LIMIT_MB=1536
```
