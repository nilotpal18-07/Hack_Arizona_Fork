const express = require("express");

const app = express();

require("./db"); // To run mongoose.connect() code from db.js

app.listen(8080, () => {
  console.log("Serving on port 8080");
});
