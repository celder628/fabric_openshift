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

kubectl delete cm ${orderer_name}
kubectl delete cm ${orderer_name}-config
kubectl delete secret ${orderer_name}-msp
kubectl delete secret ${orderer_name}-tls
kubectl delete service ${orderer_name}
kubectl delete route ${orderer_name}
kubectl delete deployment ${orderer_name}
kubectl delete pvc pvc-${orderer_name}
