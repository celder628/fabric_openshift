#!/bin/bash

CONFIG=${1}

NOTPASSED=""

if [ -z "${CONFIG}" ];then
	NOTPASSED="${NOTPASSED} CONFIG"
fi

if [ ! -z "${NOTPASSED}" ]; then
	echo "${NOTPASSED} not passed"
	echo "Usage: ./startCli.sh <config>"
	exit 1
fi

cd $(dirname $0)

. ./node-config/global.config
. ./node-config/${CONFIG}
. ./node-config/${ca_config}

bash -c "PATH=${PWD}/bin:$PATH \
FABRIC_CFG_PATH=./config  \
CORE_PEER_ADDRESS=${peer_name}.${domain}:443 \
CORE_PEER_LOCALMSPID=${mspid} \
CORE_PEER_TLS_ENABLED=true \
CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/enrollments/${ca_name}/${peer_name}/tls/cacerts/ca-cert.pem" \
CORE_PEER_TLS_CERT_FILE="${PWD}/enrollments/${ca_name}/${peer_name}/tls/signcerts/cert.pem" \
CORE_PEER_TLS_KEY_FILE="${PWD}/enrollments/${ca_name}/${peer_name}/tls/keystore/key.pem" \
CORE_PEER_MSPCONFIGPATH="${PWD}/enrollments/${ca_name}/${org_admin}/msp" \
bash"
