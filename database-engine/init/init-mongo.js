// init-mongo.js
db = db.getSiblingDB('test');  
db.createCollection('test');  
db.test.insertOne({ "message": "MongoDB is working 🚀" });
