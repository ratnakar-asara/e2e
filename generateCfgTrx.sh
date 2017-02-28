#!/bin/bash

CHANNEL_NAME=$1
if [ -z "$1" ]; then
	echo "Setting channel to default name 'mychannel'"
	CHANNEL_NAME="mychanel"
fi

echo "Channel name - "$CHANNEL_NAME
echo

CURRENT_DIR=$PWD

#Backup the original configtx.yaml
cp ../../common/configtx/tool/configtx.yaml ../../common/configtx/tool/configtx.yaml.orig
cp configtx.yaml ../../common/configtx/tool/configtx.yaml

cd $PWD/../../
echo "Building configtxgen"
make configtxgen

echo "Generating genesis block"
configtxgen -profile TwoOrgs -outputBlock orderer.block
mv orderer.block examples/e2e/crypto/orderer/orderer.block

echo "Generating channel configuration transaction"
configtxgen -profile TwoOrgs -outputCreateChannelTx channel.tx -channelID $CHANNEL_NAME
mv channel.tx examples/e2e/crypto/orderer/channel.tx

#reset configtx.yaml file to its original
cp common/configtx/tool/configtx.yaml.orig common/configtx/tool/configtx.yaml
rm common/configtx/tool/configtx.yaml.orig

cd $CURRENT_DIR
