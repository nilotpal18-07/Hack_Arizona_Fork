const express = require("express");
const path = require("path");
const ejsMate = require("ejs-mate");
const methodOverride = require("method-override");
const session = require("express-session");
const bcrypt = require("bcryptjs");
const passport = require("passport");
const LocalStrategy = require("passport-local");

const User = require("./models/User");
const Coursework = require("./models/Coursework");
const { attachCurrentUser, requireAuth, requireRole } = require("./middleware/auth");

const app = express();

require("./db"); // To run mongoose.connect() code from db.js

app.engine("ejs", ejsMate);
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

app.use(express.urlencoded({ extended: true }));
app.use(methodOverride("_method"));

app.use(
  session({
    secret: process.env.SESSION_SECRET || "dev_secret_change_me",
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: "lax",
      maxAge: 1000 * 60 * 60 * 24 * 7, // 7 days
    },
  })
);

passport.use(
  new LocalStrategy(
    { usernameField: "email", passwordField: "password" },
    async (email, password, done) => {
      try {
        const user = await User.findOne({ email: String(email).toLowerCase().trim() });
        if (!user) return done(null, false, { message: "Invalid email or password" });

        const ok = await bcrypt.compare(String(password), user.passwordHash);
        if (!ok) return done(null, false, { message: "Invalid email or password" });

        return done(null, user);
      } catch (err) {
        return done(err);
      }
    }
  )
);

passport.serializeUser((user, done) => done(null, user._id.toString()));
passport.deserializeUser(async (id, done) => {
  try {
    const user = await User.findById(id);
    return done(null, user || false);
  } catch (err) {
    return done(err);
  }
});

app.use(passport.initialize());
app.use(passport.session());
app.use(attachCurrentUser);

app.use(express.static(path.join(__dirname, "public"), { index: false }));

app.get("/", (req, res) => {
  res.render("index", {
    title: "Home",
    styles: ["/home.css"],
    bodyClass: "page--full",
    mainClass: "page page--full",
  });
});

app.get("/sign-in", (req, res) => {
  res.render("sign-in", {
    title: "Sign in",
    styles: ["/sign-in.css"],
    bodyClass: "page--full",
    mainClass: "page page--full",
  });
});

app.get("/sign-up", (req, res) => {
  res.render("sign-up", {
    title: "Sign up",
    styles: ["/sign-in.css"],
    bodyClass: "page--full",
    mainClass: "page page--full",
  });
});

app.post("/sign-in", async (req, res, next) => {
  passport.authenticate("local", {
    successRedirect: "/",
    failureRedirect: "/sign-in",
  })(req, res, next);
});

app.post("/sign-up", async (req, res, next) => {
  try {
    const { username, email, password } = req.body || {};
    if (!email || !password) return res.status(400).send("Missing credentials");

    const normalizedEmail = String(email).toLowerCase().trim();
    const existing = await User.findOne({ email: normalizedEmail }).select("_id");
    if (existing) return res.status(409).send("Email already in use");

    const passwordHash = await bcrypt.hash(String(password), 10);
    const user = await User.create({
      username: username ? String(username).trim() : undefined,
      email: normalizedEmail,
      passwordHash,
      role: "user",
      streakCount: 0,
      xp: 0,
      level: 1,
      progress: {},
    });

    req.login(user, (err) => {
      if (err) return next(err);
      return res.redirect("/");
    });
  } catch (err) {
    return next(err);
  }
});

app.post("/sign-out", (req, res) => {
  req.logout(() => {
    res.redirect("/sign-in");
  });
});

// Protected routes (examples)
app.get("/coursework", requireAuth, async (req, res, next) => {
  try {
    const coursework = await Coursework.findOne({ isPublished: true })
      .sort({ level: 1, createdAt: -1 })
      .lean();
    res.render("coursework", { title: "Coursework", coursework });
  } catch (err) {
    next(err);
  }
});

app.get("/profile", requireAuth, (req, res) => {
  res.send(`Profile (protected) - ${res.locals.currentUser?.email || ""}`);
});

app.get("/streaks", requireAuth, (req, res) => {
  res.send("Streaks (protected)");
});

// Admin-only example
app.get("/admin", requireAuth, requireRole("admin"), (req, res) => {
  res.send("Admin only");
});

const port = Number.parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Serving on port ${port}`);
});
