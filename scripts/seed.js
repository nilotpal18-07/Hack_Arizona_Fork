/* eslint-disable no-console */
require("../db");

const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("../models/User");
const Coursework = require("../models/Coursework");

async function seed() {
  const now = new Date();
  const passwordHash = await bcrypt.hash("password123", 10);

  const coursework = {
    slug: "food-bank-foundations",
    title: "Food Bank Foundations",
    description: "Learn core terms and flow of a food bank visit.",
    language: "en",
    level: 1,
    isPublished: true,
    units: [
      {
        slug: "unit-1",
        title: "Getting Started",
        description: "Basics and first-day wins.",
        order: 1,
        lessons: [
          {
            slug: "basics-1",
            title: "Basics 1",
            description: "Greetings and key phrases.",
            xp: 10,
            order: 1,
            isPublished: true,
            content: { type: "quiz", questions: 5 },
          },
          {
            slug: "basics-2",
            title: "Basics 2",
            description: "Listening and matching.",
            xp: 15,
            order: 2,
            isPublished: true,
            content: { type: "quiz", questions: 7 },
          },
          {
            slug: "food-bank-tour",
            title: "Food Bank Tour",
            description: "Vocabulary you’ll see on site.",
            xp: 20,
            order: 3,
            isPublished: true,
            content: { type: "lesson", sections: 4 },
          },
        ],
      },
    ],
  };

  const users = [
    {
      username: "demo",
      email: "demo@hackarizona.local",
      passwordHash,
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
      passwordHash,
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
      passwordHash,
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

  // Upsert coursework and enroll demo user
  const cw = await Coursework.findOneAndUpdate(
    { slug: coursework.slug },
    coursework,
    { upsert: true, returnDocument: "after", setDefaultsOnInsert: true }
  );

  const demo = await User.findOne({ email: "demo@hackarizona.local" });
  if (demo) {
    demo.enrolledCourseworks = [cw._id];
    demo.courseworkProgress = [
      {
        coursework: cw._id,
        activeUnitSlug: "unit-1",
        activeLessonSlug: "food-bank-tour",
        completedLessonSlugs: ["basics-1", "basics-2"],
        xpEarned: 45,
        lastActivityAt: now,
      },
    ];
    await demo.save();
  }

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

