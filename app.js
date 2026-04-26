require("dotenv").config({ path: "./model/.env" });
const express = require("express");
const path = require("path");
const ejsMate = require("ejs-mate");
const methodOverride = require("method-override");
const session = require("express-session");
const bcrypt = require("bcryptjs");
const passport = require("passport");
const LocalStrategy = require("passport-local");
const Anthropic = require("@anthropic-ai/sdk");

const User = require("./models/User");
const Coursework = require("./models/Coursework");
const Quiz = require("./models/Quiz");
const { attachCurrentUser, requireAuth, requireRole } = require("./middleware/auth");

const anthropic = process.env.ANTHROPIC_API_KEY
  ? new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })
  : null;

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

app.get("/", async (req, res, next) => {
  try {
    const [coursework, quizzes, allUsers] = await Promise.all([
      Coursework.findOne({ isPublished: true }).sort({ level: 1 }).lean(),
      Quiz.find({ isPublished: true }).sort({ createdAt: -1 }).lean(),
      User.find({}, "xp").lean(),
    ]);
    const myXp = res.locals.currentUser?.xp || 0;
    const behind = allUsers.filter(u => (u.xp || 0) < myXp).length;
    const aheadPct = allUsers.length > 1
      ? Math.round((behind / (allUsers.length - 1)) * 100)
      : 100;
    res.render("index", {
      title: "Home",
      styles: ["/home.css"],
      bodyClass: "page--full",
      mainClass: "page page--full",
      coursework,
      quizzes,
      aheadPct,
    });
  } catch (err) { next(err); }
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

// Profile
app.get("/profile", requireAuth, (req, res) => {
  res.render("profile", {
    title: "Profile",
    styles: ["/home.css", "/quiz-builder.css"],
    bodyClass: "page--full",
    mainClass: "page page--full",
  });
});

app.post("/profile", requireAuth, async (req, res, next) => {
  try {
    const { username, email, currentPassword, newPassword, confirmPassword } = req.body;
    const user = await User.findById(res.locals.currentUser._id);

    if (username) user.username = String(username).trim();
    if (email) user.email = String(email).toLowerCase().trim();

    if (newPassword) {
      if (newPassword !== confirmPassword) {
        return res.render("profile", {
          title: "Profile",
          styles: ["/home.css", "/quiz-builder.css"],
          bodyClass: "page--full",
          mainClass: "page page--full",
          flash: "New passwords do not match.",
        });
      }
      const ok = await bcrypt.compare(String(currentPassword || ""), user.passwordHash);
      if (!ok) {
        return res.render("profile", {
          title: "Profile",
          styles: ["/home.css", "/quiz-builder.css"],
          bodyClass: "page--full",
          mainClass: "page page--full",
          flash: "Current password is incorrect.",
        });
      }
      user.passwordHash = await bcrypt.hash(String(newPassword), 10);
    }

    await user.save();
    res.redirect("/profile");
  } catch (err) { next(err); }
});

// Leaderboard
app.get("/leaderboard", requireAuth, async (req, res, next) => {
  try {
    const allUsers = await User.find({}, "username email xp streakCount level courseworkProgress").sort({ xp: -1 }).lean();
    const myId = res.locals.currentUser?._id?.toString();
    const myRank = allUsers.findIndex(u => u._id.toString() === myId) + 1;
    const myXp = res.locals.currentUser?.xp || 0;
    const behind = allUsers.filter(u => (u.xp || 0) < myXp).length;
    const aheadPct = allUsers.length > 1
      ? Math.round((behind / (allUsers.length - 1)) * 100)
      : 100;
    res.render("leaderboard", {
      title: "Leaderboard",
      styles: ["/home.css", "/coordinator.css", "/leaderboard.css"],
      bodyClass: "page--full",
      mainClass: "page page--full",
      allUsers,
      myRank,
      aheadPct,
    });
  } catch (err) { next(err); }
});

// Chatbot
app.post("/chat", requireAuth, express.json(), async (req, res) => {
  const { message } = req.body || {};
  if (!message) return res.json({ reply: "Please type a message." });

  if (!anthropic) {
    return res.json({
      reply: "Chatbot not configured — add ANTHROPIC_API_KEY to model/.env to enable AI responses.",
    });
  }

  try {
    const response = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 300,
      system: "You are a friendly assistant for the Community Food Bank volunteer training program. Answer questions about lessons, quests, food bank operations, and volunteer resources. Keep responses concise (2-3 sentences max).",
      messages: [{ role: "user", content: String(message).slice(0, 500) }],
    });
    res.json({ reply: response.content[0]?.text || "I'm not sure about that. Try asking your coordinator!" });
  } catch (err) {
    res.json({ reply: "I'm having trouble responding right now. Please try again shortly." });
  }
});

app.get("/streaks", requireAuth, (req, res) => {
  res.redirect("/leaderboard");
});

// Quiz builder
app.get("/coordinator/quiz/new", requireAuth, (req, res) => {
  res.render("quiz-builder", {
    title: "Quiz Builder",
    styles: ["/home.css", "/quiz-builder.css"],
    bodyClass: "page--full",
    mainClass: "page page--full",
  });
});

app.post("/coordinator/quiz", requireAuth, async (req, res, next) => {
  try {
    const { title, description, unit, xp, questions, published } = req.body;
    let parsed = [];
    try { parsed = JSON.parse(questions || "[]"); } catch (_) {}

    await Quiz.create({
      title: String(title || "").trim(),
      description: String(description || "").trim(),
      unit: String(unit || "").trim(),
      xp: Number(xp) || 20,
      isPublished: published === "true",
      questions: parsed,
      createdBy: req.user?._id,
    });

    res.redirect("/coordinator");
  } catch (err) {
    next(err);
  }
});

// Coordinator dashboard (Dashboard 2)
app.get("/coordinator", requireAuth, async (req, res, next) => {
  try {
    const allUsers = await User.find({}, "username email streakCount xp level courseworkProgress lastStreakDate createdAt").lean();

    const now = Date.now();
    const participants = allUsers.map(u => {
      const daysSinceActivity = u.lastStreakDate
        ? Math.floor((now - new Date(u.lastStreakDate)) / 86400000)
        : 99;
      const lessonsCompleted = (u.courseworkProgress || []).reduce(
        (sum, p) => sum + (p.completedLessonSlugs?.length || 0), 0
      );
      // Simple risk heuristic: streak=0 + no recent activity + low xp
      const riskPct = Math.min(
        100,
        (u.streakCount === 0 ? 30 : 0) +
        (daysSinceActivity > 5 ? 35 : daysSinceActivity > 2 ? 15 : 0) +
        (u.xp < 30 ? 20 : u.xp < 80 ? 10 : 0) +
        (lessonsCompleted === 0 ? 15 : 0)
      );
      const riskLevel = riskPct >= 65 ? "high" : riskPct >= 40 ? "med" : "low";

      let lastActivity;
      if (daysSinceActivity === 0) lastActivity = "Today";
      else if (daysSinceActivity === 1) lastActivity = "Yesterday";
      else if (daysSinceActivity < 99) lastActivity = `${daysSinceActivity} days ago`;
      else lastActivity = "Never";

      return {
        id: u._id.toString(),
        name: u.username || u.email.split("@")[0],
        email: u.email,
        streak: u.streakCount || 0,
        xp: u.xp || 0,
        lessonsCompleted,
        riskPct,
        riskLevel,
        lastActivity,
        status: riskPct >= 65 ? "flagged" : riskPct >= 40 ? "watching" : "resolved",
        triggers: buildTriggers(u, daysSinceActivity),
      };
    });

    participants.sort((a, b) => b.riskPct - a.riskPct);

    const stats = {
      total: participants.length,
      highRisk: participants.filter(p => p.riskLevel === "high").length,
      resolved: participants.filter(p => p.status === "resolved").length,
      graduated: 0,
    };

    const quizzes = await Quiz.find({}, "title unit isPublished createdAt").sort({ createdAt: -1 }).lean();

    res.render("coordinator", {
      title: "Coordinator Dashboard",
      styles: ["/coordinator.css", "/home.css"],
      bodyClass: "page--full",
      mainClass: "page page--full",
      participants,
      stats,
      quizzes,
    });
  } catch (err) {
    next(err);
  }
});

function buildTriggers(u, daysSinceActivity) {
  const t = [];
  if (daysSinceActivity > 5 && u.streakCount === 0) t.push("missing");
  if (u.xp < 30) t.push("motivation");
  if ((u.courseworkProgress || []).reduce((s, p) => s + (p.completedLessonSlugs?.length || 0), 0) === 0) {
    if (daysSinceActivity > 2) t.push("overwhelmed");
  }
  return t;
}

// Admin-only example
app.get("/admin", requireAuth, requireRole("admin"), (req, res) => {
  res.send("Admin only");
});

const port = Number.parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Serving on port ${port}`);
});
