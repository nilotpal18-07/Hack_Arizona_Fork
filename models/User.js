const mongoose = require("mongoose");

const { Schema } = mongoose;

const courseworkProgressSchema = new Schema(
  {
    coursework: { type: Schema.Types.ObjectId, ref: "Coursework", required: true, index: true },
    activeUnitSlug: { type: String, default: "" },
    activeLessonSlug: { type: String, default: "" },
    completedLessonSlugs: { type: [String], default: [] },
    xpEarned: { type: Number, default: 0, min: 0 },
    lastActivityAt: { type: Date },
  },
  { _id: false }
);

const userSchema = new Schema(
  {
    username: {
      type: String,
      trim: true,
      minlength: 2,
      maxlength: 32,
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
      maxlength: 254,
    },
    passwordHash: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      enum: ["user", "admin"],
      default: "user",
      index: true,
    },

    enrolledCourseworks: {
      type: [{ type: Schema.Types.ObjectId, ref: "Coursework" }],
      default: [],
    },
    courseworkProgress: {
      type: [courseworkProgressSchema],
      default: [],
    },

    // Duolingo-like game state
    streakCount: {
      type: Number,
      default: 0,
      min: 0,
    },
    lastStreakDate: {
      type: Date,
    },
    xp: {
      type: Number,
      default: 0,
      min: 0,
    },
    level: {
      type: Number,
      default: 1,
      min: 1,
    },

    // Track quest/course progress (simple flexible shape for now)
    progress: {
      type: Schema.Types.Mixed,
      default: {},
    },
  },
  { timestamps: true }
);

userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ enrolledCourseworks: 1 });

module.exports = mongoose.models.User || mongoose.model("User", userSchema);

