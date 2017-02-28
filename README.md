<center> <h1> V1.0 End-to-End flow</h1> </center>

Verified on the commit level : **7134f9f270317958fc5718762882930c3a2d4a38**


###Two approaches for End-to-End flow verification in Fabric V1.0

###1) Using Docker Images

Clone fabric repo
```
git clone https://github.com/hyperledger/fabric.git
```


### Pre-reqs

* Generate all **Organization certificates** using behave.
```
cd fabric/bddtests
behave -k -D cache-deployment-spec features/bootstrap.feature
```
*  **configtxgen tool**  can be used to create fabric **channel configuration transaction** and orderer **bootstrap block**
.More details can be obtained [here](https://github.com/hyperledger/fabric/blob/master/docs/configtxgen.md)
Also refer the [configtx.yaml](https://github.com/ratnakar-asara/e2e/blob/master/configtx.yaml) available in this repo, which explains creating two Organizations , each consists of two peers.

       A script [generateCfgTrx.sh](https://github.com/ratnakar-asara/e2e/blob/master/generateCfgTrx.sh) can be used to generate these artifacts.

How to use the script
```
./generateCfgTrx.sh <channel-id>
```
**OR** 

you can generate using the below commands. However you need to replace the file configtx.yaml avilable [here](generateCfgTrx.sh)
and use these artifacts instead the ones available

```
make configtxgen

# Generate orderer bootstrap genesis block
configtxgen -profile TwoOrgs -outputBlock <block-name>

#Generate channel configuration transaction
configtxgen -profile TwoOrgs -outputCreateChannelTx <cfg txn name> -channelID <channel-id>
```

* Generate docker-images
```
make peer-docker orderer-docker
```
Upon success you will see all the images similar to below

```
$ docker images
REPOSITORY                     TAG                             IMAGE ID            CREATED             SIZE
hyperledger/fabric-orderer     latest                          0743df66ddd1        3 hours ago         179 MB
hyperledger/fabric-orderer     x86_64-0.7.0-snapshot-2c8bcf0   0743df66ddd1        3 hours ago         179 MB
hyperledger/fabric-peer        latest                          cec5da3b2e68        3 hours ago         183 MB
hyperledger/fabric-peer        x86_64-0.7.0-snapshot-2c8bcf0   cec5da3b2e68        3 hours ago         183 MB
hyperledger/fabric-javaenv     latest                          fbc9ceda5166        3 hours ago         1.42 GB
hyperledger/fabric-javaenv     x86_64-0.7.0-snapshot-2c8bcf0   fbc9ceda5166        3 hours ago         1.42 GB
hyperledger/fabric-ccenv       latest                          5f296d780c1d        3 hours ago         1.29 GB
hyperledger/fabric-ccenv       x86_64-0.7.0-snapshot-2c8bcf0   5f296d780c1d        3 hours ago         1.29 GB
hyperledger/fabric-baseimage   x86_64-0.3.0                    f4751a503f02        2 weeks ago         1.27 GB
hyperledger/fabric-baseos      x86_64-0.3.0                    c3a4cf3b3350        2 weeks ago         161 MB
```


##How to run a sample End to End

clone ths repo under examples directory

```
cd examples
git clone https://github.com/ratnakar-asara/e2e.git

cd e2e
```


spin the network using docker-compose file

```
[CHANNEL_NAME=<channel-id>] docker-compose up -d
```

You must see 5 containers (**_solo orderer_**, 4 **_peers_** and one **_cli_** container) as below
```
CONTAINER ID        IMAGE                        COMMAND                  CREATED              STATUS              PORTS                                            NAMES
bb4c16656b8b        hyperledger/fabric-peer      "sh -c './script.s..."   About a minute ago   Up About a minute                                                    cli
58aca57f193b        hyperledger/fabric-peer      "peer node start -..."   About a minute ago   Up About a minute   0.0.0.0:9051->7051/tcp, 0.0.0.0:9053->7053/tcp   peer2
097d338f6178        hyperledger/fabric-peer      "peer node start -..."   About a minute ago   Up About a minute   0.0.0.0:8051->7051/tcp, 0.0.0.0:8053->7053/tcp   peer1
530e4e7492de        hyperledger/fabric-peer      "peer node start -..."   About a minute ago   Up About a minute   0.0.0.0:7051->7051/tcp, 0.0.0.0:7053->7053/tcp   peer0
5bfd502d5551        hyperledger/fabric-orderer   "orderer"                About a minute ago   Up About a minute   0.0.0.0:7050->7050/tcp                           orderer
```
**OR**

you can simply use the available shell script to run the sample

```
./network_setup.sh restart [chain-id]
```

### How to create a channel and join the peers to the channel

A shellscript **script.sh** is baked inside the cli conatiner, The script will do the below things for you:

* _Creates a channel_ **mychannel** (this is default if you don't supply input to docker-compose or network_setup.sh) with configuration transaction generated using configtxgen tool **channel.tx** (this is mounted to cli container)

 As a result of this command **mychannel.block** will get created on the file system

* PEER0 & PEER1 from Org0 and PEER2 & PEER3 from Org1 , will **Join** the channel mychannel.

* **Install** chaincode *chaincode_example02*  on a remote PEER0 of Org0 and PEER2 of Org1

* **Instantiate** chaincode from peer2 (At this point you will see a chaincode container **_dev-peer2-mycc-1.0_**) also notice there is a Policy specified with **-P**

* **Query** chaincode on peer0 and notice the result with 100, also notice the chaincode container ***dev-peer0-mycc-1.0***

* **Invoke** chaincode on peer0 (wait for few secs to complete the tx)

* **Install** chaincode on *chaincode_example02*  on a remote PEER3 of Org1

* **Query** chaincode on peer3 (see chaincode container, dev-peer3-mycc-1.0)

#### How do I see the above said actions ?
check the cli docker container logs
```
docker logs -f cli
```

At the end of the result you will see something like below:
```
2017-02-28 04:31:20.841 UTC [logging] InitFromViper -> DEBU 001 Setting default logging level to DEBUG for command 'chaincode'
2017-02-28 04:31:20.842 UTC [msp] GetLocalMSP -> DEBU 002 Returning existing local MSP
2017-02-28 04:31:20.842 UTC [msp] GetDefaultSigningIdentity -> DEBU 003 Obtaining default signing identity
2017-02-28 04:31:20.843 UTC [msp] Sign -> DEBU 004 Sign: plaintext: 0A8F050A59080322096D796368616E6E...6D7963631A0A0A0571756572790A0161 
2017-02-28 04:31:20.843 UTC [msp] Sign -> DEBU 005 Sign: digest: 52F1A41B7B0B08CF3FC94D9D7E916AC4C01C54399E71BC81D551B97F5619AB54 
Query Result: 90
2017-02-28 04:31:30.425 UTC [main] main -> INFO 006 Exiting.....
===================== Query on chaincode on PEER3 on channel 'mychannel' is successful ===================== 

===================== All GOOD, End-2-End execution completed ===================== 

```

#### How can I see chaincode logs ?
you can see from chaincode containers
Here is the combined output from each container 
```
$ docker logs dev-peer2-mycc-1.0
04:30:45.947 [BCCSP_FACTORY] DEBU : Initialize BCCSP [SW]
ex02 Init
Aval = 100, Bval = 200

$ docker logs dev-peer0-mycc-1.0
04:31:10.569 [BCCSP_FACTORY] DEBU : Initialize BCCSP [SW]
ex02 Invoke
Query Response:{"Name":"a","Amount":"100"}
ex02 Invoke
Aval = 90, Bval = 210

$ docker logs dev-peer3-mycc-1.0
04:31:30.420 [BCCSP_FACTORY] DEBU : Initialize BCCSP [SW]
ex02 Invoke
Query Response:{"Name":"a","Amount":"90"}


```

## How do I create channel and join the peers of my interest

Please refer the commands available in **script.sh** 
these commands are to create a channel and join peers to the channel

Coming soon : <<provide all the commands here>>
For any of the following commands to work, you would need to set the below Envirpnment variables

```
	# Environment variables for PEER0
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peer/peer0/localMspConfig
	CORE_PEER_ADDRESS=peer0:7051
	CORE_PEER_LOCALMSPID="Org0MSP"
```

####Create channel

Specify the name of the channel  with **-c** option and **-f** must be suplied with Channel creation transaction i.e., **channel.tx** (In this case it is **channelTx** , you can mount your own channel txn )
```
 peer channel create -c mychannel -f channel.tx
```

####Join channel

Join peers of your intrest
```
 peer channel join -b mychannel.block
```

####Install chaincode remotely
Installing chaincode onto remote peer **peer1**
```
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_sample 
```

####Instantiate chaincode
Instantiate chaincode, this will launch a chaincode container
```
peer chaincode instantiate -C mychannel -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_sample -c '{"Args":["init","a", "100", "b","200"]}' -P "AND('Org1MSP.member')"
```
**NOTE**: How to sepcify policy ? mode details can be [here](https://github.com/hyperledger/fabric/blob/master/docs/endorsement-policies.md)
####Invoke chaincode

```
https://github.com/hyperledger/fabric/blob/master/docs/endorsement-policies.md
peer chaincode invoke -C mychannel -n mycc -c '{"function":"invoke","Args":["nvoke","a","b","10"]}'
```

**NOTE** Make sure you wait for few seconds

####Query chaincode

```
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
```
The result of the above command should be as below

```
Query Result: 90
```

###2) Vagrant Environment NON Default chainid(Using native binaries)
```
vagrant ssh
```
Make sure you clear the folder `/var/hyperledger/` after each run
```
rm -rf /var/hyperledger/*
```
Execute following commands from fabric
```
cd /opt/gopath/src/github.com/hyperledger/fabric
```

Build the executables orderer and peer with `make native` command
 

Vagrant window 1 - **start orderer**
```
ORDERER_GENERAL_LOGLEVEL=debug orderer
```

####Create a channel
Vagrant window 2 - ask orderer to **create a chain**

```
peer channel create -c mychannel -f channel.tx
```

On successful creation, a genesis block **mychannel.block** is saved in current directory

####Join channel
Vagrant window 3 - start the peer in a _**"chainless"**_ mode
```
peer node start --peer-defaultchain=false
```

Vagrant window 2 - peer to join a channel
```
peer channel join -b mychannel.block
```

where **mychannel.block** is the block that was received from the orderer from the create channel command.


####Deploy chaincode
Chaincode dpeloy is a two step process
1) **Install** & 
2) **Instantiate**

####Install
```
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_sample
```

####Instantiate
```
peer chaincode instantiate -C myc1 -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_sample -c '{"Args":[""]}'
```

####Invoke
```
peer chaincode invoke -C myc1 -n mycc -c '{"function":"invoke","Args":["put","a","yugfoiuehyorye87y4yiushdofhjfjdsfjshdfsdkfsdifsdpiupisupoirusoiuou"]}'
```
**NOTE** wait for few seconds

####Query
```
peer chaincode query -C myc1 -n mycc -c '{"function":"invoke","Args":["get","a"]}'
```

###Troubleshoot

If you are see the below error 
```
Error: Error endorsing chaincode: rpc error: code = 2 desc = Error installing chaincode code mycc:1.0(chaincode /var/hyperledger/production/chaincodes/mycc.1.0 exits)
```

Probably you have the images (ex **_peer0-peer0-mycc-1.0_** or **_peer1-peer0-mycc1-1.0_**) from your prevoous runs
Remove them and retry again. here is a helper command

```
docker rmi -f $(docker images | grep peer[0-9]-peer[0-9] | awk '{print $3}')
```

###Misc
Now you can launch network using a shell script
```
./network_setup up 
```
Default option is to use hyperledger images

If you don't want to build fabric images, you can use my images by supplying the docker-compose file
```
./network_setup up docker-compose-ratnakar.yaml
```

To cleanup the network, use **down**  option with the command
```
./network_setup down
```
