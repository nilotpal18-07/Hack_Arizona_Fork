const mongoose = require("mongoose");

// Remove the { useNewUrlParser: true } object entirely
mongoose.connect("mongodb://127.0.0.1:27017/hack-arizona")
  .then(() => {
    console.log("Database connected");
  })
  .catch((err) => {
    console.error("Connection error:", err);
  });

const db = mongoose.connection;

module.exports = mongoose;