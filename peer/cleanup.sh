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

kubectl delete cm ${peer_name}
kubectl delete cm ${peer_name}-config
kubectl delete cm ${peer_name}-external-builder
kubectl delete secret ${peer_name}-msp
kubectl delete secret ${peer_name}-tls
kubectl delete service ${peer_name}
kubectl delete route ${peer_name}
kubectl delete deployment ${peer_name}
kubectl delete pvc pvc-${peer_name}
