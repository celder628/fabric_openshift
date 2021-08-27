#!/bin/bash

CONFIG=${1}

NOTPASSED=""

if [ -z "${CONFIG}" ];then
	NOTPASSED="${NOTPASSED} CONFIG"
fi

if [ ! -z "${NOTPASSED}" ]; then
	echo "${NOTPASSED} not passed"
	echo "Usage: ./createEnrollment.sh <config>"
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

rm -rf "${PWD}/../enrollments/${ca_name}/${orderer_name}/msp"
rm -rf "${PWD}/../enrollments/${ca_name}/${orderer_name}/tls"

fabric-ca-client enroll -d -u https://${node_user}:${node_user_password}@${ca_name}.${domain} --caname tlsca --mspdir "${PWD}/../enrollments/${ca_name}/${orderer_name}/tls" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem" --csr.hosts "${orderer_name}.${domain}, 127.0.0.1"

fabric-ca-client enroll -d -u https://${node_user}:${node_user_password}@${ca_name}.${domain} --caname ca --mspdir "${PWD}/../enrollments/${ca_name}/${orderer_name}/msp" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem"

renameCerts "$PWD/../enrollments/${ca_name}/${orderer_name}/msp"
renameCerts "$PWD/../enrollments/${ca_name}/${orderer_name}/tls"
