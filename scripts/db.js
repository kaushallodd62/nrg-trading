const { MongoClient } = require('mongodb');

// Connection URI and database name
const uri = 'mongodb://localhost:27017';
const dbName = 'mydatabase';

// Create a new MongoClient
const client = new MongoClient(uri);

// Connect to the MongoClient
client.connect(err => {
  if (err) {
    console.log(err);
    return;
  }

  console.log('Connected successfully to server');

  // Get the database object
  const db = client.db(dbName);

  // Create a new collection
  const collection = db.collection('users');

  // Insert some documents
  collection.insertMany([
    {
      userid: 1,
      name: 'John Doe',
      email: 'johndoe@example.com',
      isProducer: false,
      isConsumer: true,
      registerDate: new Date('2022-01-01')
    },
    {
      userid: 2,
      name: 'Jane Smith',
      email: 'janesmith@example.com',
      isProducer: true,
      isConsumer: false,
      registerDate: new Date('2022-01-02')
    },
    {
      userid: 3,
      name: 'Bob Johnson',
      email: 'bobjohnson@example.com',
      isProducer: true,
      isConsumer: true,
      registerDate: new Date('2022-01-03')
    }
  ], (err, result) => {
    if (err) {
      console.log(err);
      return;
    }

    console.log(`${result.insertedCount} documents inserted into the collection`);

    // Find all documents in the collection
    collection.find({}).toArray((err, documents) => {
      if (err) {
        console.log(err);
        return;
      }

      console.log(`Found ${documents.length} documents in the collection`);
      console.log(documents);
    });

    // Find documents that match a query
    collection.find({ isProducer: true }).toArray((err, documents) => {
      if (err) {
        console.log(err);
        return;
      }

      console.log(`Found ${documents.length} documents that match the query`);
      console.log(documents);
    });
  });
});
