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

const MODEL1_URL = process.env.MODEL1_URL || "http://localhost:7000";
const MODEL2_URL = process.env.MODEL2_URL || "http://localhost:7001";

async function callAPI(url, method = "GET", body = null) {
  const opts = { method, headers: { "Content-Type": "application/json" } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(url, opts);
  if (!res.ok) throw new Error(`API ${method} ${url} → ${res.status}`);
  return res.json();
}

const app = express();

const mongoose = require("./db"); // To run mongoose.connect() code from db.js

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

// Chatbot — proxies to Model 2 (Python) for participant-aware responses
app.post("/chat", requireAuth, express.json(), async (req, res) => {
  const { message } = req.body || {};
  if (!message) return res.json({ reply: "Please type a message." });

  const user = res.locals.currentUser;

  // Resolve participant_id: check session cache, then look up by email, then default P001
  if (!req.session.participantId) {
    try {
      const db = mongoose.connection.db;
      const p = await db.collection("participants").findOne({
        $or: [{ email: user?.email }, { name: user?.username }],
      });
      req.session.participantId = p ? (p.participant_id || String(p._id)) : "P001";
    } catch (_) {
      req.session.participantId = "P001";
    }
  }

  try {
    const data = await callAPI(`${MODEL2_URL}/chat`, "POST", {
      participant_id: req.session.participantId,
      message: String(message).slice(0, 500),
    });
    return res.json({
      reply: data.reply || "I'm not sure about that. Try asking your coordinator!",
      sentiment: data.sentiment,
      flag_coordinator: data.flag_coordinator,
    });
  } catch (err) {
    // Fallback to direct Anthropic if Model 2 is offline
    if (!anthropic) return res.json({ reply: "Chatbot service is currently offline. Please try again shortly." });
    try {
      const response = await anthropic.messages.create({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 300,
        system: "You are Mise, a warm supportive assistant for Caridad Community Kitchen culinary training program in Tucson AZ run by Community Food Bank of Southern Arizona. Be warm, concise, and encouraging. Never be preachy.",
        messages: [{ role: "user", content: String(message).slice(0, 500) }],
      });
      return res.json({ reply: response.content[0]?.text || "I'm not sure about that. Try asking your coordinator!" });
    } catch (e) {
      return res.json({ reply: "I'm having trouble responding right now. Please try again shortly." });
    }
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
    const db = mongoose.connection.db;

    const [rawParticipants, riskEvents, interventions, quizzes] = await Promise.all([
      db.collection("participants").find({}).toArray(),
      db.collection("risk_events").find({ resolved: false }).toArray(),
      db.collection("interventions").find({}).toArray(),
      Quiz.find({}, "title unit isPublished createdAt").sort({ createdAt: -1 }).lean(),
    ]);

    // ── Fetch live risk scores from Model 1 Python API ──────────────────────
    let mlScores = [];
    try {
      mlScores = await callAPI(`${MODEL1_URL}/risk-scores`);
    } catch (_) {
      // Fall back to MongoDB risk_scores if Model 1 is offline
      try {
        const mongoScores = await db.collection("risk_scores").find({}).toArray();
        const latestMongo = {};
        for (const rs of mongoScores) {
          const pid = rs.participant_id;
          if (!latestMongo[pid] || rs.week_number > latestMongo[pid].week_number) latestMongo[pid] = rs;
        }
        mlScores = Object.values(latestMongo).map(rs => ({
          participant_id: rs.participant_id,
          risk_score:     Math.round((rs.risk_score || 0) * 100),
          alert_level:    rs.risk_tier === "high" ? "red" : rs.risk_tier === "medium" ? "yellow" : "green",
          shap_factor_1:  rs.top_features ? Object.keys(rs.top_features)[0] : "",
          week_number:    rs.week_number,
        }));
      } catch (_2) { /* leave mlScores empty */ }
    }

    // Index ML scores by participant_id
    const mlByPid = {};
    for (const s of mlScores) mlByPid[s.participant_id] = s;

    // Index unresolved risk events per participant
    const unresolvedEvents = {};
    const triggerTypeMap = {
      transport_barrier: "transport", housing_instability: "housing",
      childcare_load_change: "childcare", financial_stress_spike: "financial",
      motivation_drop: "motivation", feeling_overwhelmed: "overwhelmed",
      missing_reminders: "missing",
    };
    for (const ev of riskEvents) {
      const pid = ev.participant_id;
      if (!unresolvedEvents[pid]) unresolvedEvents[pid] = [];
      unresolvedEvents[pid].push(triggerTypeMap[ev.trigger_type] || ev.trigger_type);
    }

    // ── Build participant rows ───────────────────────────────────────────────
    // Merge MongoDB participant details with Model 1 ML risk scores
    const allRows = [];

    // Rows from MongoDB participants
    for (const p of rawParticipants) {
      const pid = p.participant_id || String(p._id);
      const ml  = mlByPid[pid] || {};
      const riskPct  = ml.risk_score ?? 0;
      const alertLvl = ml.alert_level || "green";
      const riskLevel = alertLvl === "red" ? "high" : alertLvl === "yellow" ? "med" : "low";
      const watchStatus = alertLvl === "red" ? "flagged" : alertLvl === "yellow" ? "watching" : "resolved";
      const triggers = unresolvedEvents[pid] || [];
      const shap = [ml.shap_factor_1, ml.shap_factor_2, ml.shap_factor_3].filter(Boolean);

      allRows.push({
        id: pid,
        name: p.name || `${p.first_name || ""} ${p.last_name || ""}`.trim(),
        email: p.email || "",
        phone: p.phone || "",
        status: p.status || "active",
        riskPct,
        riskLevel,
        triggers,
        watchStatus,
        enrollmentDate: p.enrollment_date || p.enrollmentDate || "",
        topFeatures: shap.join(" · ") || null,
        week: ml.week_number || p.program_week || null,
      });
      delete mlByPid[pid]; // mark as consumed
    }

    // Rows from Model 1 that aren't in MongoDB (seeded demo participants)
    for (const [pid, ml] of Object.entries(mlByPid)) {
      const alertLvl  = ml.alert_level || "green";
      const riskLevel = alertLvl === "red" ? "high" : alertLvl === "yellow" ? "med" : "low";
      const shap = [ml.shap_factor_1, ml.shap_factor_2, ml.shap_factor_3].filter(Boolean);
      allRows.push({
        id: pid,
        name: ml.name || pid,
        email: "", phone: "", status: "active",
        riskPct:      ml.risk_score ?? 0,
        riskLevel,
        triggers:     [],
        watchStatus:  alertLvl === "red" ? "flagged" : alertLvl === "yellow" ? "watching" : "resolved",
        enrollmentDate: "",
        topFeatures:  shap.join(" · ") || null,
        week:         ml.week_number || ml.program_week || null,
      });
    }

    allRows.sort((a, b) => b.riskPct - a.riskPct);

    const stats = {
      total:                allRows.length,
      highRisk:             allRows.filter(p => p.riskLevel === "high").length,
      resolved:             allRows.filter(p => p.watchStatus === "resolved").length,
      graduated:            rawParticipants.filter(p => p.status === "graduated").length,
      pendingInterventions: interventions.filter(i => i.outcome === "pending").length,
    };

    res.render("coordinator", {
      title:     "Coordinator Dashboard",
      styles:    ["/coordinator.css", "/home.css"],
      bodyClass: "page--full",
      mainClass: "page page--full",
      participants: allRows,
      stats,
      quizzes,
    });
  } catch (err) {
    next(err);
  }
});

// Refresh all ML risk scores on demand
app.post("/coordinator/refresh-scores", requireAuth, async (_req, res) => {
  try {
    const result = await callAPI(`${MODEL1_URL}/predict-all`, "POST");
    res.json({ ok: true, scored: result.scored });
  } catch (err) {
    res.status(502).json({ ok: false, error: err.message });
  }
});

// Admin-only example
app.get("/admin", requireAuth, requireRole("admin"), (req, res) => {
  res.send("Admin only");
});

const port = Number.parseInt(process.env.PORT || "8080", 10);
app.listen(port, () => {
  console.log(`Serving on port ${port}`);
});
