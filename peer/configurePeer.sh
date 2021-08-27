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
template="$(cat peer-template.yaml)"
eval "echo \"${template}\"" > ${peer_name}.yaml

rm -rf "${PWD}/../enrollments/${ca_name}/${peer_name}/msp"
rm -rf "${PWD}/../enrollments/${ca_name}/${peer_name}/tls"

fabric-ca-client enroll -d -u https://${node_user}:${node_user_password}@${ca_name}.${domain} --caname tlsca --mspdir "${PWD}/../enrollments/${ca_name}/${peer_name}/tls" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem" --csr.hosts "${peer_name}.${domain}, 127.0.0.1"

fabric-ca-client enroll -d -u https://${node_user}:${node_user_password}@${ca_name}.${domain} --caname ca --mspdir "${PWD}/../enrollments/${ca_name}/${peer_name}/msp" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem"

renameCerts "$PWD/../enrollments/${ca_name}/${peer_name}/msp"
renameCerts "$PWD/../enrollments/${ca_name}/${peer_name}/tls"

kubectl create secret generic ${peer_name}-msp \
  --from-file=admincerts=../enrollments/${ca_name}/${org_admin}/msp/signcerts/cert.pem \
	--from-file=cacerts=../enrollments/${ca_name}/${peer_name}/msp/cacerts/ca-cert.pem \
	--from-file=keystore=../enrollments/${ca_name}/${peer_name}/msp/keystore/key.pem \
	--from-file=signcerts=../enrollments/${ca_name}/${peer_name}/msp/signcerts/cert.pem

kubectl create secret generic ${peer_name}-tls \
	--from-file=cacerts=../enrollments/${ca_name}/${peer_name}/tls/cacerts/ca-cert.pem \
	--from-file=keystore=../enrollments/${ca_name}/${peer_name}/tls/keystore/key.pem \
	--from-file=signcerts=../enrollments/${ca_name}/${peer_name}/tls/signcerts/cert.pem

kubectl create configmap ${peer_name} --from-file=../config/core.yaml

kubectl create configmap ${peer_name}-config --from-file=config.yaml

kubectl create configmap ${peer_name}-external-builder --from-file=./external-builder

kubectl apply -f ${peer_name}.yaml

rm ${peer_name}.yaml
