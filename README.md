# MongoDB 3-node replica set in Docker Swarm cluster

Usage: `./start.sh <docker hub repo name>`

### What is this for?

The script will deploy a 3-node MongoDB replica set as described in https://docs.mongodb.com/manual/replication/ to the Docker Swarm cluster.

### Prerequisites

1. At least 3-node Docker Swarm cluster (tested on docker-ce 18.05)
2. Docker hub repository: the script builds custom MongoDB image and pushes it there so other nodes in the cluster can pull it.
3. OpenSSL

### Features
1. Replica set access control using keyFile;
2. Client connections are SSL-secured. The script will generate all necessary crypto material using OpenSSL and print the CA cert to the console;
3. Creates a user which can access the database called "mydb";
4. All created users' credentials (including admin and replica set admin) are printed to console.
