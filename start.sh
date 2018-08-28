#!/bin/bash

export REPO=$1

function print () {
  echo
  echo "--> $1"
  echo
}

function configureNodes () {
  i=0
  labels=()
  for node in $(docker node ls  -q); do
    if [ $i -eq 0 ]
    then
      label="master"
    else
      label="worker$i"
    fi
    labels[$i]=$label

    docker node update --label-add mongo.role=$label $node

    let "i++"
  done

  if [ $i -lt 3 ]
  then
    print "Need at least 3 docker nodes! Exiting..."
    exit 1
  fi
}

print "Generating mongo keyfile..."
rm -rf ./mongodb/mongo.keyfile
openssl rand -base64 756 > ./mongodb/mongo.keyfile

print "Generating SSL certs..."
cd mongodb && mkdir ssl
cd ssl
# Generate self signed root CA cert
openssl req -nodes -x509 -newkey rsa:2048 -keyout ca.key -out ca.crt -days 365 -subj "/C=CH/ST=Bern/O=MongoSwarm/CN=mongo"
print "MongoDB CA cert:"
cat ca.crt
echo ""
for host in mongo0 mongo1 mongo2; do
  # Generate server cert to be signed
  openssl req -nodes -newkey rsa:2048 -keyout $host-cert.key -out $host.csr -subj "/C=CH/ST=Bern/O=MongoSwarm/CN=$host"
  # Sign the server cert
  openssl x509 -req -in $host.csr -CA ca.crt -CAkey ca.key -CAcreateserial -days 365 -out $host-cert.crt
  cat ./$host-cert.key ./$host-cert.crt > ./$host.pem
done

cd ../..

print "Building mongdb image..."
docker build -t $REPO/mongo -f ./mongodb/Dockerfile ./mongodb/
docker push $REPO/mongo

print "Configuring Docker nodes..."
configureNodes

print "Deploying MongoDB services without auth and ssl..."
export AUTH=''
export MONGOSSL0=''
export MONGOSSL1=''
export MONGOSSL2=''
export REPO=$REPO
docker stack deploy --with-registry-auth --compose-file ./docker-compose-stack.yaml mongoswarm

docker build -t $REPO/mongodb-configurator -f ./configurator/Dockerfile ./configurator/
docker run \
  --network=mongoswarm_mongonet \
  -v /data:/data \
  -e "ENV=$ENV" \
  $REPO/mongodb-configurator

print "Restarting mongo db cluster to enable auth and ssl..."
export AUTH='--auth --keyFile /etc/mongo.keyfile'
export MONGOSSL0='--sslMode requireSSL --sslAllowConnectionsWithoutCertificates --sslPEMKeyFile /etc/mongo0.pem --sslCAFile /etc/mongo-ca.crt'
export MONGOSSL1='--sslMode requireSSL --sslAllowConnectionsWithoutCertificates --sslPEMKeyFile /etc/mongo1.pem --sslCAFile /etc/mongo-ca.crt'
export MONGOSSL2='--sslMode requireSSL --sslAllowConnectionsWithoutCertificates --sslPEMKeyFile /etc/mongo2.pem --sslCAFile /etc/mongo-ca.crt'
docker stack deploy --with-registry-auth --compose-file ./docker-compose-stack.yaml mongoswarm
