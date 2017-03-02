#!/bin/sh

# find address of orderer and peers in your network
ORDERER_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("orderer")); print "$a\n";'`
PEER0_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer0")); print "$a\n";'`
PEER1_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer1")); print "$a\n";'`
PEER2_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer2")); print "$a\n";'`
PEER3_IP=`perl -e 'use Socket; $a = inet_ntoa(inet_aton("peer2")); print "$a\n";'`

echo "-----------------------------------------"
echo "Orderer IP $ORDERER_IP"
echo "PEER0 IP $PEER0_IP"
echo "PEER1 IP $PEER1_IP"
echo "PEER2 IP $PEER2_IP"
echo "PEER3 IP $PEER3_IP"
echo "-----------------------------------------"

CORE_PEER_COMMITTER_LEDGER_ORDERER=$ORDERER_IP:7050
CHANNEL_NAME=$1
COUNTER=0
MAX_RETRY=5

if [ -z "$CHANNEL_NAME" ]; then
	echo "---- Using default channel 'mychannel'"
	CHANNEL_NAME="mychannel"
fi
echo "Channel name : "$CHANNEL_NAME

verifyResult () {
	if [ $1 -ne 0 ]; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
                echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
		echo
   		exit 1
	fi
}

setGlobals () {
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peer/peer$1/localMspConfig
	CORE_PEER_ADDRESS=peer$1:7051
	if [ $1 -eq 0 -o $1 -eq 1 ] ; then
		CORE_PEER_LOCALMSPID="Org0MSP"
	else
		CORE_PEER_LOCALMSPID="Org1MSP"
	fi
}

createChannel() {
	peer channel create -c $CHANNEL_NAME -f crypto/orderer/channel.tx>log.txt 2>&1
	res=$?
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

## Sometimes Join takes time hence RETRY atleast for 5 times
joinWithRetry () {
	peer channel join -b $CHANNEL_NAME.block >log.txt 2>&1
	res=$?
	cat log.txt
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "PEER$1 failed to join the channel, Retry after 2 seconds"
		sleep 2
		joinWithRetry $1
	else
		COUNTER=0
	fi
        verifyResult $res "After $MAX_RETRY attempts, PEER$ch has failed to Join the Channel"
}

joinChannel () {
	for ch in 0 1 2 3; do
		setGlobals $ch
		joinWithRetry $ch
		echo "===================== PEER$ch joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep 2
		echo
	done
}

#Curl is not available in peer image
#downloadChaincode () {
#	CURRENT_DIR=PWD
#	mkdir -p ../examples/chaincode/go/chaincode_example02
#	cd ../examples/chaincode/go/chaincode_example02
#	curl -O https://raw.githubusercontent.com/hyperledger/fabric/master/examples/chaincode/go/chaincode_example02/chaincode_example02.go
#	cd $CURRENT_DIR
#}


installChaincode () {
	PEER=$1
	setGlobals $PEER
	peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 >log.txt 2>&1
	res=$?
	cat log.txt
        verifyResult $res "Chaincode installation on remote peer PEER$PEER has Failed"
	echo "===================== Chaincode is installed on remote peer PEER$PEER ===================== "
	echo
}

instantiateChaincode () {
	PEER=$1
	setGlobals $PEER
	peer chaincode instantiate -C $CHANNEL_NAME -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Args":["init","a","100","b","200"]}' -P "OR	('Org0MSP.member','Org1MSP.member')" >log.txt 2>&1
	res=$?
	cat log.txt
	verifyResult $res "Chaincode instantiation on PEER$PEER on channel '$CHANNEL_NAME' failed"
	echo "===================== Chaincode Instantiation on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeQuery () {
	PEER=$1
	setGlobals $PEER
	peer chaincode query -C $CHANNEL_NAME -n mycc -c '{"Args":["query","a"]}' >log.txt 2>&1
	res=$?
	cat log.txt
	verifyResult $res "Query execution on PEER$PEER failed "
	grep -q "$2" log.txt
	verifyResult $? "Query result on PEER$PEER is INVALID "
	echo "===================== Query on chaincode on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

chaincodeInvoke () {
        PEER=$1
	peer chaincode invoke -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' >log.txt 2>&1
	res=$?
	cat log.txt
	verifyResult $res "Invoke execution on PEER$PEER failed "
	echo "===================== Invoke transaction on PEER$PEER on channel '$CHANNEL_NAME' is successful ===================== "
	echo
}

## Create channel
createChannel

## Join all the peers to the channel
joinChannel

#Download chaincode
#downloadChaincode

## Install chaincode on Peer0/Org0 and Peer2/Org1
installChaincode 0
installChaincode 2

#Instantiate chaincode on Peer2/Org1
echo "Instantiating chaincode on Peer2/Org1 ..."
instantiateChaincode 2
echo "Wait for 15 seconds ..."
sleep 15

#Query on chaincode on Peer0/Org0
chaincodeQuery 0 100

#Invoke on chaincode on Peer0/Org0
echo "send Invoke transaction on Peer0/Org0 ..."
chaincodeInvoke 0

## Install chaincode on Peer3/Org1
installChaincode 3

echo "Wait for 10 seconds ..."
sleep 10

#Query on chaincode on Peer3/Org1, check if the result is 90
chaincodeQuery 3 90

echo "===================== All GOOD, End-2-End execution completed ===================== "
exit 0
