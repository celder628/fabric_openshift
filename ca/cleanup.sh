#!/bin/bash

CONFIG=${1}

NOTPASSED=""

if [ -z "${CONFIG}" ];then
	NOTPASSED="${NOTPASSED} CONFIG"
fi

if [ ! -z "${NOTPASSED}" ]; then
	echo "${NOTPASSED} not passed"
	echo "Usage: ./cleanup.sh <config>"
	exit 1
fi

cd $(dirname $0)

. ../node-config/${CONFIG}

kubectl delete cm ${ca_name}-ca
kubectl delete cm ${ca_name}-tlsca
kubectl delete secret ${ca_name}-msp
kubectl delete secret ${ca_name}-tls
kubectl delete service ${ca_name}
kubectl delete route ${ca_name}
kubectl delete deployment ${ca_name}
kubectl delete pvc pvc-${ca_name}
