/* eslint-disable no-console */
require("../db");

const mongoose = require("mongoose");
const User = require("../models/User");

async function seed() {
  const now = new Date();

  const users = [
    {
      username: "demo",
      email: "demo@hackarizona.local",
      passwordHash: "demo_password_hash",
      streakCount: 7,
      lastStreakDate: now,
      xp: 420,
      level: 3,
      progress: {
        unit: 1,
        quests: {
          basics1: { status: "done", stars: 3 },
          basics2: { status: "done", stars: 3 },
          foodBankTour: { status: "current", stars: 0 },
        },
      },
    },
    {
      username: "tanmay",
      email: "tanmay@hackarizona.local",
      passwordHash: "tanmay_password_hash",
      streakCount: 2,
      lastStreakDate: now,
      xp: 120,
      level: 1,
      progress: {
        unit: 1,
        quests: {
          basics1: { status: "current", stars: 1 },
        },
      },
    },
    {
      username: "alex",
      email: "alex@hackarizona.local",
      passwordHash: "alex_password_hash",
      streakCount: 0,
      xp: 0,
      level: 1,
      progress: {},
    },
  ];

  // replace these emails if they already exist
  const emails = users.map((u) => u.email);
  const del = await User.deleteMany({ email: { $in: emails } });
  const ins = await User.insertMany(users);

  console.log(`Deleted ${del.deletedCount} existing dummy users`);
  console.log(`Inserted ${ins.length} users`);
}

seed()
  .then(() => mongoose.connection.close())
  .catch((err) => {
    console.error(err);
    mongoose.connection.close();
    process.exitCode = 1;
  });

