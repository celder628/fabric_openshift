#!/bin/bash

CONFIG=${1}

NOTPASSED=""

if [ -z "${CONFIG}" ];then
	NOTPASSED="${NOTPASSED} CONFIG"
fi

if [ ! -z "${NOTPASSED}" ]; then
	echo "${NOTPASSED} not passed"
	echo "Usage: ./configureCA.sh <config>"
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

waitForCAToStart () {
  while [[ $(curl -s $1 | jq .success) != "true" ]]; do echo "waiting for CA to start" && sleep 30; done
}

cd $(dirname $0)

. ../node-config/global.config
. ../node-config/${CONFIG}
template="$(cat ca-template.yaml)"
eval "echo \"${template}\"" > ${ca_name}.yaml

kubectl create configmap ${ca_name}-ca --from-file=fabric-ca-server-config.yaml

kubectl create configmap ${ca_name}-tlsca --from-file=tls-fabric-ca-server-config.yaml

kubectl apply -f ${ca_name}.yaml

waitForCAToStart "-k https://${ca_name}.${domain}/cainfo"

rm -rf "${PWD}/../enrollments/${ca_name}"

mkdir -p "${PWD}/../enrollments/${ca_name}"

openssl s_client -servername ${ca_name}.${domain} -connect ${ca_name}.${domain}:443 2>/dev/null </dev/null |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "${PWD}/../enrollments/${ca_name}/tls-cert.pem"

fabric-ca-client enroll -d -u https://${ca_admin}:${ca_admin_password}@${ca_name}.${domain} --caname tlsca --mspdir "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls" --tls.certfiles "${PWD}/../enrollments/${ca_name}/tls-cert.pem" --csr.hosts "${ca_name}.${domain}, 127.0.0.1"

fabric-ca-client enroll -d -u https://${ca_admin}:${ca_admin_password}@${ca_name}.${domain} --caname ca --mspdir "${PWD}/../enrollments/${ca_name}/${ca_admin}/msp" --tls.certfiles "${PWD}/../enrollments/${ca_name}/tls-cert.pem"

renameCerts "$PWD/../enrollments/${ca_name}/${ca_admin}/msp"
renameCerts "$PWD/../enrollments/${ca_name}/${ca_admin}/tls"

kubectl create secret generic ${ca_name}-msp \
  --from-file=cacerts=../enrollments/${ca_name}/${ca_admin}/msp/cacerts/ca-cert.pem \
  --from-file=keystore=../enrollments/${ca_name}/${ca_admin}/msp/keystore/key.pem \
  --from-file=signcerts=../enrollments/${ca_name}/${ca_admin}/msp/signcerts/cert.pem

kubectl create secret generic ${ca_name}-tls \
  --from-file=cacerts=../enrollments/${ca_name}/${ca_admin}/tls/cacerts/ca-cert.pem \
  --from-file=keystore=../enrollments/${ca_name}/${ca_admin}/tls/keystore/key.pem \
  --from-file=signcerts=../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem

kubectl get deployment ${ca_name} -o json > ${ca_name}-temp.json

cat ${ca_name}-temp.json | jq '.spec.template.spec.containers[0].env += [{"name": "FABRIC_CA_SERVER_TLS_CERTFILE", "value": "/cert/tls/cert.pem"},{"name": "FABRIC_CA_SERVER_TLS_KEYFILE", "value": "/cert/tls/key.pem"}]' \
 | jq '.spec.template.spec.containers[0].volumeMounts += [{"mountPath": "/cert/tls", "name": "tls"}]' \
 | jq '.spec.template.spec.volumes += [{"name": "tls", "secret": {"secretName": "'${ca_name}'-tls", "items": [{"key":"keystore","path":"key.pem","mode":0420},{"key":"signcerts","path":"cert.pem","mode":0420}] }}]' \
 > ${ca_name}-update.json

kubectl apply -f ${ca_name}-update.json

waitForCAToStart "https://${ca_name}.${domain}/cainfo --cert ${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem --key ${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/keystore/key.pem --cacert ${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/cacerts/ca-cert.pem"

fabric-ca-client register -d -u https://${ca_name}.${domain} --caname ca --id.name ${org_admin} --id.secret ${org_admin_password} --id.type admin --id.attrs "hf.Registrar.Roles=client,hf.Registrar.Attributes=*,hf.Revoker=true,hf.GenCRL=true,admin=true:ecert,abac.init=true:ecert" --mspdir "${PWD}/../enrollments/${ca_name}/${ca_admin}/msp" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem"

fabric-ca-client register -d -u https://${ca_name}.${domain} --caname ca --id.name ${node_user} --id.secret ${node_user_password} --id.type ${node_type} --mspdir "${PWD}/../enrollments/${ca_name}/${ca_admin}/msp" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem"

fabric-ca-client register -d -u https://${ca_name}.${domain} --caname tlsca --id.name ${node_user} --id.secret ${node_user_password} --id.type ${node_type} --mspdir "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem"

fabric-ca-client enroll -d -u https://${org_admin}:${org_admin_password}@${ca_name}.${domain} --caname ca --mspdir "${PWD}/../enrollments/${ca_name}/${org_admin}/msp" --tls.certfiles "${PWD}/../enrollments/${ca_name}/${ca_admin}/tls/signcerts/cert.pem"

renameCerts "$PWD/../enrollments/${ca_name}/${org_admin}/msp"
mkdir -p ../enrollments/${ca_name}/${org_admin}/msp/admincerts
cp ../enrollments/${ca_name}/${org_admin}/msp/signcerts/cert.pem ../enrollments/${ca_name}/${org_admin}/msp/admincerts/cert.pem

#Recreate the MSP
rm -rf ../organizations/${mspid}

mkdir -p ../organizations/${mspid}/admincerts
mkdir -p ../organizations/${mspid}/cacerts
mkdir -p ../organizations/${mspid}/tlscacerts
mkdir -p ../organizations/${mspid}/users

cp ../enrollments/${ca_name}/${org_admin}/msp/signcerts/cert.pem ../organizations/${mspid}/admincerts/cert.pem
cp ../enrollments/${ca_name}/${ca_admin}/msp/cacerts/ca-cert.pem ../organizations/${mspid}/cacerts/ca-cert.pem
cp ../enrollments/${ca_name}/${ca_admin}/tls/cacerts/ca-cert.pem ../organizations/${mspid}/tlscacerts/ca-cert.pem
cp ./config.yaml ../organizations/${mspid}/config.yaml


rm ${ca_name}-update.json
rm ${ca_name}-temp.json
rm ${ca_name}.yaml
