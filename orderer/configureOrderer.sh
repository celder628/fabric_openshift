#!/bin/bash

CONFIG=${1}

NOTPASSED=""

if [ -z "${CONFIG}" ];then
	NOTPASSED="${NOTPASSED} CONFIG"
fi

if [ ! -z "${NOTPASSED}" ]; then
	echo "${NOTPASSED} not passed"
	echo "Usage: ./configurePeer.sh <config>"
	exit 1
fi

renameCerts () {
  SRCDIR=$1
  for file in $SRCDIR/cacerts/*;do
          mv "$file" $SRCDIR/cacerts/ca-cert.pem
          echo $file
  done
  for file in $SRCDIR/keystore/*;do
          mv "$file" $SRCDIR/keystore/key.pem
          echo $file
  done
}

cd $(dirname $0)

. ../node-config/global.config
. ../node-config/${CONFIG}
. ../node-config/${ca_config}
template="$(cat orderer-template.yaml)"
eval "echo \"${template}\"" > ${orderer_name}.yaml

kubectl create secret generic ${orderer_name}-msp \
  --from-file=admincerts=../enrollments/${ca_name}/${org_admin}/msp/signcerts/cert.pem \
	--from-file=cacerts=../enrollments/${ca_name}/${orderer_name}/msp/cacerts/ca-cert.pem \
	--from-file=keystore=../enrollments/${ca_name}/${orderer_name}/msp/keystore/key.pem \
	--from-file=signcerts=../enrollments/${ca_name}/${orderer_name}/msp/signcerts/cert.pem

kubectl create secret generic ${orderer_name}-tls \
	--from-file=cacerts=../enrollments/${ca_name}/${orderer_name}/tls/cacerts/ca-cert.pem \
	--from-file=keystore=../enrollments/${ca_name}/${orderer_name}/tls/keystore/key.pem \
	--from-file=signcerts=../enrollments/${ca_name}/${orderer_name}/tls/signcerts/cert.pem

kubectl create configmap ${orderer_name} --from-file=../config/orderer.yaml --from-file=../channel_artifacts/genesis.block

kubectl create configmap ${orderer_name}-config --from-file=config.yaml

kubectl apply -f ${orderer_name}.yaml

rm ${orderer_name}.yaml
