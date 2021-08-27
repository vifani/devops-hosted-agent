# Introduction
This repository contains resources to build a Docker image containing Visual Studio Build Tools and an Azure DevOps Agent. This image can be used to deploy a **self-hosted Windows Azure DevOps Build agent**.

# Build Docker Image on Windows
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
az acr create --resource-group devopsagent --name vifani --sku Basic
```
- Build the image
```
az acr build --registry vifani -t windows-build-agent:v1.0 --platform windows .
```
After the build you can use the hosting you prefer to run the container image: Azure Kubernetes Service, Azure Container Instance or Web App for Containers