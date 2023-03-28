const { MongoClient } = require("mongodb");
 
// Replace the following with your Atlas connection string                                                                                                                                        
const url = "mongodb+srv://abhishek:abhishek@cluster0.7mvnmiz.mongodb.net/?retryWrites=true&w=majority";
const client = new MongoClient(url);

const dbName = "mydatabase";

// const userDataSchema = {
//   userid: Number,
//   name: String,
//   email: String,
//   isProducer: Boolean,
//   isConsumer: Boolean,
//   registerDate: Date
// };

async function run() {
    try {
        await client.connect();
        console.log("Connected correctly to server");
        const db = client.db(dbName);
        // Use the collection "people"
        const col = db.collection("users");

        // Construct a document                                                                                                                                                              
        let personDocument = {
          "userid": 1,
          "name": { "first": "Alan", "last": "Turing" },
          "email": "alanturing@gmail.com",
          "isProducer": true,
          "isConsumer": true,
          "registerDate": new Date(1912, 5, 23) // May 23, 1912                                                                                                                                 
          
      }
      // Insert a single document, wait for promise so we can read it back
      const p = await col.insertOne(personDocument);
      // Find one document
      const myDoc = await col.findOne();
      // Print to the console
      console.log(myDoc);

        

    } catch (err) {
        console.log(err.stack);
    }
    finally {
        await client.close();
    }
}


run().catch(console.dir);