<!--<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fazure%2Fazure-quickstart-templates%2Fmaster%2Fmysql-replication%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fmysql-replication%2Fazuredeploy.json" target="_blank">
  <img src="http://armviz.io/visualizebutton.png"/>
</a>
-->
# Aerospike Cluster Template

This template deploys an Aerospike cluster.  It has the following capabilities:

- Deploys 3 VMs in an Azure VNet.
- Installs LIS4 driver on each VM. Note that the VMs are not automatically rebooted, so LIS4 will not take effect until the next time a VM reboots

### How to Deploy
You can deploy the template with Azure Portal, or PowerShell, or Azure cross platform command line tools. 

**Default deployment**

1. The example here uses PowerShell to deploy.

  * Open Azure Powershell console, and log in by running Login-AzureRmAccount command.
  ```sh
  > Login-AzureRmAccount 
  ```
  * Next, create a resource group:
  ```sh
  > New-AzureRMResourceGroup -Name "aerospikerg"-Location "East US"
  ```
  * Create a deployment:
  ```sh
  > New-AzureRMResourceGroupDeployment -ResourceGroupName aerospikerg -TemplateFile .\azuredeploy.json -TemplateParameterFile .\azuredeploy.parameters.json
  ```
  
2. The example here uses Azure CLI on Linux to deploy.
  
  * Login by using the `azure login` command.
  ```bash
  $ azure login
  ```
  * Next, create a resource group:
  ```bash
  $ azure group create --name aerospikerg --location "West US"
  ```
  * Create a deployment:
  ```bash
  $ azure group deployment create --name aerospikedeployment --resource-group aerospikerg --template-file azuredeploy.json --parameters-file azuredeploy.parameters.json
  ```

**Custom deployment**
* Take a look at AzureDeploy.json to see if you need to make any customization that's not exposed through the template parameters, for example, disk configurations.  If you do, download the template and make modifications locally.
* Take a look at `azure_aerospike.sh`.  This script configures clustering and custom namespaces.
* If you make changes to `azure_aerospike.sh`, you need to put the modified file in your own GitHub repo, Azure storage account or other publiclly available http download location, and modify the parameters `customScriptFilePath` point to your file location.
* Once you are done with customization, deploy using the same command as default deployment.

### How to Access Aerospike
* Access Aerospike using the public ip. The first node's public IP is given as the output of this template. Any node's IP is sufficient to establish a connection to the entire cluster, as the [smart clients](http://www.aerospike.com/docs/architecture/clients.html) will perform a round of discovery. By default, the cluster can be accessed at port 3000.
```sh
> asadm -h <YOUR_AEROSPIKE_SERVER>
```
* You can access the VMs through ssh.  By default, public ssh port is 22.

* Ensure clustering is healthy:
```sh
> asadm -h <YOUR_AEROSPIKE_SERVER> -e info
```


### How to backup Namespaces to Azure blob storage
* The example below shows asbackup.

```sh
# Create backups directory if not already created (modify folder as required)
> mkdir  /home/admin/backups/

# Install npm and azure-cli
# For latest instructions for installing azure cli see https://azure.microsoft.com/en-in/documentation/articles/xplat-cli-install/. (sample commands below)
> sudo yum update -y
> sudo yum upgrade -y
> sudo yum install epel-release -y
> sudo yum install nodejs -y
> sudo yum install npm -y
> sudo npm install -g azure-cli

# Login to azure account using azure cli 
> azure login

# Environment settings for your system
> export AZURE_STORAGE_ACCOUNT=aeropsikebkp
> export AZURE_STORAGE_ACCESS_KEY=<your access key>
> export image_to_upload=/home/admin/backups/db_bkp.gz
> export container_name=<your azure container name>
> export blob_name=db-backup-$(date +%m-%d-%Y-%H%M%S).gz
> export destination_folder=<your azure destination folder name>

> cd /home/admin/backups/

# Remove previous backup file
> rm -Rf $image_to_upload

# Take backup and compress
> asbackup --namespace $namespace --output-file - | gzip -9 > $image_to_upload

# Move the backup to Azure Blob storage
> azure storage blob upload $image_to_upload $container_name $blob_name
 
```
