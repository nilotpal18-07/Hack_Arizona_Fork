const express = require("express");
const path = require("path");

const app = express();

require("./db"); // To run mongoose.connect() code from db.js

app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

const port = Number.parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Serving on port ${port}`);
});
