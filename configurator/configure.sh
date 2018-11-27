#!/bin/bash

DB_NAME=mydb
USER=user

MAX_RETRY=10
COUNTER=1

function print () {
  echo
  echo "--> $1"
  echo
}

verifyResult () {
	if [ $1 -ne 0 ] ; then
		echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to configure mongo cluster =================="
		echo
   	exit 1
	fi
}

waitForRS () {
  ismaster=$(mongo --host mongo0 --quiet --eval 'db.isMaster().ismaster')
  [ $ismaster == 'true' ]
  res=$?
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "RS is not configured yet, continue waiting..."
		sleep 5
		waitForRS $1
	else
		COUNTER=1
	fi
  verifyResult $res "After $MAX_RETRY attempts, replica set is not configured, giving up."
}

checkMongoHost () {
	mongo --host $1 --eval 'db.isMaster().ismaster === true'
	res=$?
	if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
		COUNTER=` expr $COUNTER + 1`
		echo "$1 host is not up, retrying after 5 seconds..."
		sleep 5
		checkMongoHost $1
	else
		COUNTER=1
	fi
  verifyResult $res "After $MAX_RETRY attempts, mongo sevice $1 is not up, giving up."
}

function waitForMongo () {
  checkMongoHost mongo0
  checkMongoHost mongo1
  checkMongoHost mongo2
}

function genPwd () {
  passw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
}

function configureRS () {
  # Connect to rs1 and configure replica set if not done
  count=$(mongo --host mongo0 --quiet --eval 'rs.status().members.length')
  if [ $? -ne 0 ]; then
    echo "Replica set is not configured."

    # Replicaset not yet configured
    mongo --host mongo0 rs.js
    verifyResult $? "Failed to configure replica set."

    waitForRS

    echo "Creating users in mongodb..."

    genPwd
    ADMIN_PWD=$passw

    genPwd
    CLUSTER_ADMIN_PWD=$passw

    genPwd
    USER_PWD=$passw

    mongo --host mongo0 \
      --eval "var adminPwd = '$ADMIN_PWD', clusterAdminPwd = '$CLUSTER_ADMIN_PWD',  userPwd = '$USER_PWD', dbName = '$DB_NAME', userName = '$USER'" \
     configure.js

    verifyResult $? "Failed to create users in a replica set."

    print "Important database data (write it down!)"
    echo "Admin: admin/$ADMIN_PWD" | tee mongo.txt
    echo "Replica admin: replicaAdmin/$CLUSTER_ADMIN_PWD" | tee -a mongo.txt
    echo "$DB_NAME user: $USER/$USER_PWD" | tee -a mongo.txt
    MONGO_URL="mongodb://$USER:$USER_PWD@mongo0:27017,mongo1:27017,mongo2:27017/$DB_NAME?replicaSet=mongoRS"
    echo "MONGO_URL=$MONGO_URL"
    echo $MONGO_URL > /data/mongo-url.txt
  else
    echo "Got $count nodes in a set, skipping configuration."
  fi
}

print "Waiting for mongo services..."
waitForMongo
print "All mongo services are up"

print "Configuring replica set..."
configureRS
print "Replica set configured."
