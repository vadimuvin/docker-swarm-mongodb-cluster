rs.initiate({
  _id: 'mongoRS',
  members: [
    { _id: 0, host : 'mongo0', priority: 1 },
    { _id: 1, host : 'mongo1', priority: 0.5 },
    { _id: 2, host : 'mongo2', priority: 0.5 }]
  })
