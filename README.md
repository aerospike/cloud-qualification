# Cloud Certification

This project contains scripts that will:

1. Create an Aerospike cluster
2. Create client systems
3. Run YCSB from client systems against the Aerospike cluster
4. Change Aerospike parameters and reset the cluster
5. Repeat 3 and 4 until all parameters are exhausted

With 100M objects, this process takes ~1 hour per YCSB test.

This project can be utilized in several ways:

1. Running a simple YCSB test with a pre-defined aerospike config
2. Finding the limits of a particular instance/environment
3. Finding the impact of Aerospike configuration changes

## Requirements

* Boto3 for Python `sudo pip install --upgrade boto3`
  * AWS credentials pre-configured at ~/.aws/credentials
* certificate based login to all systems

## Parameters
Parameters are in the following dimensions:

### 1. Server Parameters
Server side parameters such as write-block-size and service-threads.  
The default configs are held in `aerospike.conf`. A parameter *needs* to be defined in `aerospike.conf` in order for the Tests section of `params.yaml` to be applied. Otherwise the YCSB test will just run against your default config.
See the Tests section of `params.yaml`

### 2. Instance Parameters
#### EC2 ####
Aerospike instance size as in the cluster size, and instance type  
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

The data should be preloaded to be near 50% of disk fnd 60% of memory for worst-case scenario. Object size would vary depending on ratio of memory to disk, to suit the instance type. This would be the limit for a 2 node cluster (due to replication factor of 2). Then add another node. The resulting 3 node cluster would form the basis for this test.

To calculate record size and number of objects:

* Disk used = (Record Size + 128) * Number of Objects
* Memory used = 64 * Number of Objects

Data preload is done using YCSB's load phase. 

**Running the Cloud Qualification**

_AWS_

The default settings are already configured for qualifying on instances with 30GB of ram.

Edit `workload-aerospike` with the number of objects and object size as determined from above. `recordcount` and `operationcount` should match. Make sure that `maxexecutiontime` is long enough to run the entire test.

Edit `params.yaml` such that the `Tests` section contains only the following:

```
write-block-size: 1024,1024,2
```
This will result in only a single pass of testing, and all Aerospike parameters are kept at default (write block size at 1M)

The `-l` parameter for `run_benchmark.py` is used to set the target ops/s.

## Usage:

Create an environment using the respective `create_*_stack` script.

Once the environment is up, use run\_bench.py to run the actual benchmarks.

```
usage: run_bench.py [-h] [-v] -c CONFIG -n NAMESPACE [-d [DEPLOYMENT]]
                    [-p [PROJECT]] [-t [TEMPLATE]] [-l [LOAD]] [-z [THREADS]]

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
  -l [LOAD], --load [LOAD]
                        The target ops/s for YCSB
  -z [THREADS], --threads [THREADS]
                        The thread count for YCSB
```

## TODO

* GCP versions


## Files

* cft - Directory of EC2 **C**loud**F**ormation **T**emplates. Used in spinning up an EC2 stack
* scripts - Directory of scripts that may be used on the Aerospike Servers themselves for additional configurations
* README.md - This README file
* aerospike.conf - The default Aerospike configuration
* aerospike.jinja - GCP template for creating Aerospike instances
* aerospike.jinja.schema - GCP template for parameter validation
* config.yaml - GCP config file 
* create\_ec2\_stack - script to create an EC2 stack
* params.yaml - The main config file for this project
* requirements.txt - Python requirements file
* run\_bench.py - The main script that runs the YCSB tests
* workload-aerospike - The YCSB workload file that's run by YCSB for the benchmarking.

```
├── aerospike.conf
├── cft
│   ├── aerospike.json
│   └── clients.json
├── config.yaml
├── create_ec2_stack
├── create_graphs.py
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
