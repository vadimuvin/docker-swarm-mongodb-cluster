admin = db.getSiblingDB('admin')

// create admin
admin.createUser(
  {
    user: 'admin',
    pwd: adminPwd,
    roles: [ { role: 'userAdminAnyDatabase', db: 'admin' } ]
  }
)

// create replica admin
db.getSiblingDB('admin').auth('admin', adminPwd)
db.getSiblingDB('admin').createUser(
  {
    user: 'replicaAdmin',
    pwd: clusterAdminPwd,
    roles: [ { role: 'clusterAdmin', db: 'admin' } ]
  }
)

// create database user
db = db.getSiblingDB(dbName)
db.createUser(
  {
    user: userName,
    pwd: userPwd,
    roles: [ { role: 'readWrite', db: dbName } ]
  }
)
