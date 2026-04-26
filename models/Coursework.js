const mongoose = require("mongoose");

const { Schema } = mongoose;

const lessonSchema = new Schema(
  {
    slug: { type: String, required: true, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    xp: { type: Number, default: 10, min: 0 },
    order: { type: Number, default: 0, min: 0 },
    isPublished: { type: Boolean, default: true },
    content: { type: Schema.Types.Mixed, default: {} }, // flexible: questions, videos, etc.
  },
  { _id: false }
);

const unitSchema = new Schema(
  {
    slug: { type: String, required: true, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    order: { type: Number, default: 0, min: 0 },
    lessons: { type: [lessonSchema], default: [] },
  },
  { _id: false }
);

const courseworkSchema = new Schema(
  {
    slug: { type: String, required: true, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    language: { type: String, default: "en" },
    level: { type: Number, default: 1, min: 1 },
    isPublished: { type: Boolean, default: true, index: true },

    units: { type: [unitSchema], default: [] },

    createdBy: { type: Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

courseworkSchema.index({ slug: 1 }, { unique: true });

module.exports =
  mongoose.models.Coursework || mongoose.model("Coursework", courseworkSchema);

