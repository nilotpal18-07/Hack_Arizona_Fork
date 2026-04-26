const mongoose = require("mongoose");

const { Schema } = mongoose;

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
      unique: true,
      lowercase: true,
      trim: true,
      maxlength: 254,
      index: true,
    },
    passwordHash: {
      type: String,
      required: true,
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

module.exports = mongoose.models.User || mongoose.model("User", userSchema);

