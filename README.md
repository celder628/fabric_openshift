# Fabric on Openshift


This is the beginning of a learning framework for installing/running Hyperledger Fabric images on OpenShift.


Begin by downloading the Fabric binaries (I downloaded for Mac):

### Download Binaries

Execute the following script to download the Fabric binaries and configure the path:

```
    ./setup.sh

    export PATH=$PWD/bin:$PATH
```


### Description

The solution uses bash scripts and templates for Peers, Orderers and Certificate Authorities.

The scripting uses a template file with config files for each component.  Config files are stored in the node-config directory.


### Creating CAs

Example config files are provided for and Org1 CA and an Orderer CA.  The shell scripts, config files and templates are located in the "ca" directory.

The following two commands run from the root directory will create the Org1 CA and Orderer1 CA.

```
  ./ca/configureCA.sh org1ca.config

  ./ca/configureCA.sh orderer1ca.config
```

The scripting will create deployments for the CAs, enrollments for the users in the config files located in a directory named "enrollments".  MSPs will be automatically generated based on the mspid and located in the "organizations" directory.


### Create Orderer


First create the enrollments for the orderer.  This is required in order to create the genesis block:

```
    ./orderer/createEnrollment.sh orderer1.config
    ./orderer/createEnrollment.sh orderer2.config
    ./orderer/createEnrollment.sh orderer3.config
```

Create the genesis block for the orderer.

The first example will create a single node orderer genesis block:

```
    configtxgen -profile SingleOrgOrdererGenesis -outputBlock ./channel_artifacts/genesis.block -channelID syschannel -configPath ./channel_config
```

This example will create a three node orderer genesis block:

```
    configtxgen -profile SingleOrgOrdererGenesis3Node -outputBlock ./channel_artifacts/genesis.block -channelID syschannel -configPath ./channel_config
```

Create a block for the application channel:

```
    configtxgen -profile SingleOrgChannel -outputCreateChannelTx ./channel_artifacts/channel1.tx -channelID channel1 -configPath ./channel_config
```

Create the orderering nodes.  Note:  Only create orderer1 for a single node ordering service.

```
    ./orderer/configureOrderer.sh orderer1.config
    ./orderer/configureOrderer.sh orderer2.config
    ./orderer/configureOrderer.sh orderer3.config
```

### Create Peer

The following command will create a peer:

```
  ./peer/configurePeer.sh peer1org1.config
```

### Start the CLI:

The peer CLI will create a shell and configure the environment variables based on the peer connection information:

```
  ./startCli.sh peer1org1.config
```

The following is an example for creating and joining a peer to a channel:

```
  peer channel create -c channel1 -f ./channel_artifacts/channel1.tx --outputBlock ./channel_artifacts/channel1.block -o orderer1.celder2-b3c-4x16-334e19b56347d9ce32b6d6a870d14f37-0000.us-south.containers.appdomain.cloud:443 --tls --cafile ${PWD}/enrollments/orderer1ca/admin/tls/cacerts/ca-cert.pem

  peer channel join -b ./channel_artifacts/channel1.block
```

### Chaincode

This is still a work in progress.  Deploying chaincode is future work.
