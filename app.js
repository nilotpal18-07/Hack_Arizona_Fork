const express = require("express");
const path = require("path");
const ejsMate = require("ejs-mate");
const methodOverride = require("method-override");

const app = express();

require("./db"); // To run mongoose.connect() code from db.js

app.engine("ejs", ejsMate);
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

app.use(express.urlencoded({ extended: true }));
app.use(methodOverride("_method"));

app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.render("index", { title: "Home" });
});

app.get("/sign-in", (req, res) => {
  res.render("sign-in", {
    title: "Sign in",
    styles: ["/sign-in.css"],
    bodyClass: "page--full",
    mainClass: "page page--full",
  });
});

const port = Number.parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Serving on port ${port}`);
});
