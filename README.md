# Cloud Qualification

This project contains scripts that will:

1. Create an Aerospike cluster
2. Create client system(s)
3. Run YCSB from client systems against the Aerospike cluster
4. Change Aerospike parameters and reset the cluster
5. Repeat 3 and 4 until all defined parameters are exhausted

With 100M objects, this process takes ~1 hour per YCSB test.

This project can be utilized in several ways:

1. Running a simple YCSB test with a pre-defined aerospike config
2. Finding the impact of Aerospike configuration changes
3. Finding the limits of a particular instance/environment

## Requirements

* SSH keys pre-generated
  * `ssh-keygen`

**AWS**
* Boto3 for Python `sudo pip install --upgrade boto3`
  * AWS credentials pre-configured at ~/.aws/credentials
* AWS account with cloudformation and ec2 privileges.

**Azure**
* Azure CLI 2.0, also signed in and authorized:
  * See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli for installation instructions
  * `azure login`

**GCP**
* `gcloud` API, signed in and authorized:
  * See https://cloud.google.com/sdk/
* Enable Deployment Manager API: https://console.cloud.google.com/flows/enableapi?apiid=deploymentmanager or from API Manager and enable Google Cloud Deployment Manager API and Google Cloud Deployment Manager V2 API
* Configure `gcloud` api:
  * `gcloud init`
* Update `gcloud`:
  * `gcloud components update core`
* oauth2client:
  * `sudo pip install --upgrade google-api-python-client oauth2client`

Parameters are in the following dimensions:

### 1. Server Parameters
Server side parameters such as write-block-size and service-threads.  
The default configs are held in `aerospike.conf`.

#### Tests Section
A parameter *needs* to be defined in `aerospike.conf` in order for the Tests section of `tests.yaml` to be applied. Otherwise the YCSB test will just run against your default config.

Tests are formated like the following:
`name: start,end,interval`

* **name** - The aerospike config parameter to change. This is case sensitive
* **start** - The starting value to test from
* **end** - The ending value
* **interval** - The interval between each successive value.

For example:
`service-threads: 2,8,2` means test the `service-threads` parameter starting from 2 until you reach 8 (or more), by increments of 2.  
Therefore, you test `service-threads` with the following values: 2,4,6,8.

_NOTE_  
For `write-block-size`, the interval is a multiplier. So `write-block-size: 128,1024,2` would mean testing `write-block-size` with values of: 128,256,512,1024.


### 2. Instance Parameters
#### EC2 ####
Aerospike Server instance size as in the cluster size, and instance type  
See the Servers section of `ec2.params`

YCSB Client instance size as in number of clients and instance type.
See the Clients section of `ec2.params`

**Notes** It is highly suggested to use spot pricing. Take a moment to check out spot pricing history and be flexible on which AZ to utilize to achieve maximum cost savings.

#### Azure ####
Aerospike Service VM size is defined in `azure-resource-manager/azuredeploy.parameters.json`

#### GCP ####
Aerospike Service VM size is defined in `gce-deployment-manager/config.yaml`

### 3. Workload

The workload is a YCSB workload config file named `workload-aerospike`. Edit this file to change how YCSB runs.

The workload defines:

 - The read/update ratio. Update is equivalent to 1 read and 1 write.
 - The access pattern (uniform, zipfian or latest)
 - Size of record
 - Number of records
 - Runtime

## Results
All results will be found in the `data/` directory. Each file will be a yaml dump of the results. The filenames are based on the Server side Test ran.

Alternatively, you can also log into the client systems and obtain the YCSB logs from $HOME/run.log and $HOME/load.log.


# Cloud Qualification

The Cloud Qualification is as follows:

The highest transactions/s (X) that can be accomplished while maintaining average read latency under 1ms.

With X being a workload of 50/50 read/updates, of uniform access pattern.

**Data Preload**

The data should be preloaded to be near 50% of disk and 60% of memory for worst-case scenario. Object size would vary depending on ratio of memory to disk, to suit the instance type. This would be the limit for a 2 node cluster (due to replication factor of 2). Then add another node. The resulting 3 node cluster would form the basis for this test.

To calculate record size and number of objects:

* Disk used = (Record Size + 128) * Number of Objects
* Memory used = 64 * Number of Objects

Data preload is done using YCSB's load phase. 

**Running the Cloud Qualification**

_AWS_

The default settings are already configured for qualifying on instances that can reserve 25GB of ram for Aerospike.

Edit `aerospike.conf` to set your namespace configs. (eg: number of devices, storage engine, memory-size, etc...)

Edit `workload-aerospike` with the number of objects and object size as determined from above. `operationcount` should be 3 times the amount of `recordcount`. Make sure that `maxexecutiontime` (in s) is long enough to run the entire test.

Make a copy of `ec2.template` and name it `ec2.params`. 

Replace the following variables with those matching your environment:

* PKey- Path to the pkey
* KeyPair - The name of the pkey within AWS
* VPC  - VPC of the Servers and Clients
* VPCSubnet - Subnet of the Servers and Clients

Create your environment:
`./create_ec2_stack -p ec2.params`

Then load your test:
`./run_bench.py -t tests.yaml -p ec2.params -n ssd -l -z 300 EC2`

Finally run your test:
`./run_bench.py -t tests.yaml -p ec2.params -n ssd -o YOUR_TARGET_OPS -z 300 -r EC2`

_AZURE_

The default settings are already configured for qualifying on instances that can reserve 25GB of ram for Aerospike.

Start by running 'git submodule init && git submodule update`. This will clone our Azure Resource Manager templates into `./azure-resource-manager`. 

Create your own namespace file and upload it to a publically accessible location (eg: github). Edit `azure-resource-manager/azuredeploy.parameters.json` with the path of the file, along with the following

* dnsName - The naming schema the VMs will have
* vmUserName - The user account that will be created on the VMs
* clusterSize - The size of the cluster
* customNamespacePath - The url to your custom namespace file
* sshPubkey - The contents of your public key, typically found at `$HOME/.ssh/id_rsa`

Copy `azure.template` to `azure.params`, then update the values needed for deployment:

* DEPLOYMENT - Give a deployment name. A new one will be created if not existing.
* RESOURCEGROUP - Give a resource group to use. A new one will be created if not existing.
* AZUREDIR - The ARM submodule path
* ZONE - Azure zone to deploy into
* PKey - Path to the pkey used above.

Finally, update `workload-aerospike` that is contained within `CloudInitScript.txt` `operationcount` should be 3 times the amount of `recordcount`. Make sure that `maxexecutiontime` (in s) is long enough to run the entire test. 


Create your environment;
`./create_azure_stack -p azure.params`

The load your test:
`./run_bench.py -t tests.yaml -p azure.params -n ssd -l -z 300 Azure`

Finally run your test:
`./run_bench.py -t tests.yaml -p azure.params -n ssd -o YOUR_TARGET_OPS -z 300 -r Azure`

_GCP_

The default settings are already configured for qualifying on instances that can reserve 25GB of ram for Aerospike.

Start by running 'git submodule init && git submodule update`. This will clone our Deployment Manager templates into `./gce-deployment-manager`.

Edit `gce-deployment-manager/config.yaml` with your parameters:

* numReplicas - The size of the cluster
* namePrefix - The name given to each machine
* zone - The zone to deploy in
* machineType - The size of each server VM
* numLocalSSDs - The number of locally attached SSDs
* useShadowDevice - How to treat the next param. If true, the number of disks will match the number of locally attached SSDs. If false, only 1 disk will be deployed.
* diskSize - The size of network attached disk(s)
* namespace - Your namespace definition

Copy `gcp.template` to `gcp.params`, then update the values needed for deployment:

* DEPLOYMENT - Give a deployment name.
* PROJECT - Your project id when you did `gcloud init`
* conffile - The path to the config.yaml file above.
* PKey - Path to the pkey used when you did `gcloud init`

Finally, update `workload-aerospike` that is contained within `CloudInitScript.txt` `operationcount` should be 3 times the amount of `recordcount`. Make sure that `maxexecutiontime` (in s) is long enough to run the entire test.


Create your environment;
`./create_gcp_stack -p gcp.params`

The load your test:
`./run_bench.py -t tests.yaml -p azure.params -n ssd -l -z 300 GCP`

Finally run your test:
`./run_bench.py -t tests.yaml -p azure.params -n ssd -o YOUR_TARGET_OPS -z 300 -r GCP`

## Usage:

Update/Edit the following files according to your requirements:  
1. **AWS/GCP** workload-aerospike - This is the YCSB workload file to use. See [Core workload properties](https://github.com/brianfrankcooper/YCSB/wiki/Core-Properties)
  * **Azure** See CloudInitScript.txt to change the workload file for Azure
2. **AWS/GCP**  aerospike.conf - This is the Aerospike config to use.
3. azure.params / ec2.params / gcp.params - This is the parameters for the cloud qualification.
4. tests.yaml - This is the test definition. See the Tests section above.
5. **Azure** azure-resource-manager/azuredeploy.parameters.json - This is the azure system parameters.



Create an environment using the respective `create_*_stack` script.

Once the environment is up, use run\_bench.py to run the actual benchmarks.

**For running a single YCSB test**  
Ensure the **Test** section of `tests.yaml` contains only a single test that doesn't change values.
eg:
```
write-block-size: 1024,1024,2
```
Run a bench using:
```
./run_bunch.py -p PARAM_FILE -t tests.yaml -n NAMESPACE -o TARGET_OPS -z YCSB_THREADS 
```
**For running a series of tests to determine impact of config changes**  
Define your tests in the **Test** section of `tests.yaml`. Then run the bench same as above.


**For testing the limits of your environment**
Run the bench without specifying `-o`, but set a high `-z`. This will allow YCSB to run as fast as it can. If you specified a `-z` that is too high, you will notice connection timeout errors during the beggining of each test.


By default, YCSB will run its loading phase followed by all the tests in the running phase. You can manually separate the loading and running phases by specifying either `-l` or `-r`, respectively. Specifying both is the same as leaving them out.

```
usage: run_bench.py [-h] [-v] -p CONFIG -t TEST -n NAMESPACE [-o [OPS]]
                    [-z [THREADS]] [-l] [-r]
                    platform

positional arguments:
  platform              Azure, GCP, or EC2

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         Enable verbose logging
  -p CONFIG, --params CONFIG
                        The param file to use
  -t TEST, --tests TEST
                        The test definition file.
  -n NAMESPACE, --namespace NAMESPACE
                        The namespace to bench against
  -o [OPS], --ops [OPS]
                        The target ops/s for YCSB
  -z [THREADS], --threads [THREADS]
                        The thread count for YCSB
  -l, --load            Run only the Loading phase (Inserts)
  -r, --run             Run only the Running phase (Read/Update)
```


## Files

* aerospike.conf - The default Aerospike configuration
* azure-resource-manager - ARM templates for starting an Aerospike Cluster in Azure
* cft - Directory of EC2 **C**loud**F**ormation **T**emplates. Used in spinning up an EC2 stack
* CloudInitScript.txt - The [CloudInit](https://cloudinit.readthedocs.io/en/latest/) script used to initialize Azure client instance.
* create\_azure\_stack - script to create an Azure stack
* create\_ec2\_stack - script to create an EC2 stack
* create\_gcp\_stack - script to create a GCP stack
* gce-deployment-manager - Deployment Manager templates for starting an Aerospike Cluster in GCP
* tests.yaml - Template for tests to run with this project
* README.md - This README file
* requirements.txt - Python PIP requirements file
* run\_bench.py - The main script that runs the YCSB tests
* scripts - Directory of scripts that may be used on the Aerospike Servers themselves for additional configurations
* workload-aerospike - The YCSB workload file that's run by YCSB for benchmarking. AWS/GCP only. For Azure, see CloudInitScript.txt
* \*.template - The configuration file templates for the respective platforms. Filled in config files are referenced as .param files throughout this document.

```
├── aerospike.conf
├── azure.template
├── azure-resource-manager
├── cft
│   ├── aerospike.json
│   └── clients.json
├── CloudInitScript.txt
├── create_azure_stack
├── create_ec2_stack
├── create_gcp_stack
├── data
├── ec2.template
├── gce-deployment-manager
├── gcp.template
├── tests.yaml
├── README.md
├── requirements.txt
├── run_bench.py
├── scripts
│   ├── aerospike_image
│   ├── balance_scsi_mq
│   ├── partition_disk
│   └── testing.cron
└── workload-aerospike
```
