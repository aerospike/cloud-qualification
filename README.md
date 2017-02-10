# Cloud Qualification

This project contains scripts that will:

1. Create an Aerospike cluster
2. Create client systems
3. Run YCSB from client systems against the Aerospike cluster
4. Change Aerospike parameters and reset the cluster
5. Repeat 3 and 4 until all parameters are exhausted

With 100M objects, this process takes ~1 hour per YCSB test.

This project can be utilized in several ways:

1. Running a simple YCSB test with a pre-defined aerospike config
2. Finding the impact of Aerospike configuration changes
3. Finding the limits of a particular instance/environment

## Requirements

* Boto3 for Python `sudo pip install --upgrade boto3`
  * AWS credentials pre-configured at ~/.aws/credentials
* certificate based login to all systems
* AWS account with cloudformation and ec2 privileges.

## Parameters
Parameters are in the following dimensions:

### 1. Server Parameters
Server side parameters such as write-block-size and service-threads.  
The default configs are held in `aerospike.conf`.

#### Tests Section
A parameter *needs* to be defined in `aerospike.conf` in order for the Tests section of `params.yaml` to be applied. Otherwise the YCSB test will just run against your default config.

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
See the Servers section of `params.yaml` 

YCSB Client instance size as in number of clients and instance type.
See the Clients section of `params.yaml`

**Notes** It is highly suggested to use spot pricing. Take a moment to check out spot pricing history and be flexible on which AZ to utilize to achieve maximum cost savings.

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

The default settings are already configured for qualifying on instances with 30GB of ram.

Edit `workload-aerospike` with the number of objects and object size as determined from above. `operationcount` should be 3 times the amount of `recordcount`. Make sure that `maxexecutiontime` (in s) is long enough to run the entire test.

Make a copy of `params.yaml.template` and name it `params.yaml`. 

Replace the following variables with those matching your environment:

* PKey
* KeyPair - Servers and Clients
* VPC  - Servers and Clients
* VPCSubnet - Servers and Clients

Create your environment:
`./create_ec2_stack -p params.yaml`

Then load your test:
`./run_bench.py -c params.yaml -n ssd -l -z 400`

Finally run your test:
`./run_bench.py -c params.yaml -n ssd -o YOUR_TARGET_OPS -z 400 -r`

## Usage:

Create an environment using the respective `create_*_stack` script.

Once the environment is up, use run\_bench.py to run the actual benchmarks.

```
usage: run_bench.py [-h] [-v] -c CONFIG -n NAMESPACE [-d [DEPLOYMENT]]
                    [-p [PROJECT]] [-t [TEMPLATE]] [-o [OPS]] [-z [THREADS]]
                    [-l] [-r]

optional arguments:
  -h, --help            show this help message and exit
  -v, --verbose         Enable verbose logging
  -c CONFIG, --config CONFIG
                        The config file to use
  -n NAMESPACE, --namespace NAMESPACE
                        The namespace to bench against
  -d [DEPLOYMENT], --deployment [DEPLOYMENT]
                        The GCE deployment
  -p [PROJECT], --project [PROJECT]
                        The GCE project
  -t [TEMPLATE], --template [TEMPLATE]
                        The CFT for aerospike server
  -o [OPS], --ops [OPS]
                        The target ops/s for YCSB
  -z [THREADS], --threads [THREADS]
                        The thread count for YCSB
  -l, --load            Run the Loading phase (Inserts)
  -r, --run             Run the Running phase (Read/Update)
```

## TODO

* GCP version


## Files

* aerospike.conf - The default Aerospike configuration
* cft - Directory of EC2 **C**loud**F**ormation **T**emplates. Used in spinning up an EC2 stack
* create\_ec2\_stack - script to create an EC2 stack
* params.yaml.template - Template for main config file for this project
* README.md - This README file
* requirements.txt - Python requirements file
* run\_bench.py - The main script that runs the YCSB tests
* scripts - Directory of scripts that may be used on the Aerospike Servers themselves for additional configurations
* workload-aerospike - The YCSB workload file that's run by YCSB for benchmarking.

```
├── aerospike.conf
├── cft
│   ├── aerospike.json
│   └── clients.json
├── create_ec2_stack
├── data
├── params.yaml.template
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
