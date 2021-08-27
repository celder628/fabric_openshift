#!/bin/bash -e

if [ "${OSTYPE}" == "linux-gnu" ]; then
    wget https://github.com/hyperledger/fabric-ca/releases/download/v1.4.7/hyperledger-fabric-ca-linux-amd64-1.4.7.tar.gz
    tar -xvf hyperledger-fabric-ca-linux-amd64-1.4.7.tar.gz
elif [[ ${OSTYPE} = darwin* ]]; then
    wget https://github.com/hyperledger/fabric-ca/releases/download/v1.4.7/hyperledger-fabric-ca-darwin-amd64-1.4.7.tar.gz
    tar -xvf hyperledger-fabric-ca-darwin-amd64-1.4.7.tar.gz
else
    echo "OS "${OS}" not supported. Please download the fabric-ca binaries manually"
    exit 1
fi

if [[ ${OSTYPE} = darwin* ]]; then
    wget https://github.com/hyperledger/fabric/releases/download/v2.2.2/hyperledger-fabric-darwin-amd64-2.2.2.tar.gz
    tar -xvf hyperledger-fabric-darwin-amd64-2.2.2.tar.gz
elif [ "${OSTYPE}" == "linux-gnu" ]; then
    wget https://github.com/hyperledger/fabric/releases/download/v2.2.2/hyperledger-fabric-linux-amd64-2.2.2.tar.gz
    tar -xvf hyperledger-fabric-linux-amd64-2.2.2.tar.gz
else
    echo "OS "${OSTYPE}" not supported. Please download the fabric tools binaries manually"
    exit 1
fi
