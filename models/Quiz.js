const mongoose = require("mongoose");

const { Schema } = mongoose;

const optionSchema = new Schema(
  { text: { type: String, required: true, trim: true } },
  { _id: false }
);

const questionSchema = new Schema(
  {
    text: { type: String, required: true, trim: true },
    type: { type: String, enum: ["multiple-choice", "true-false"], default: "multiple-choice" },
    options: { type: [optionSchema], default: [] },
    correctIndex: { type: Number, required: true, min: 0 },
    explanation: { type: String, default: "" },
  },
  { _id: false }
);

const quizSchema = new Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    unit: { type: String, default: "", trim: true },
    xp: { type: Number, default: 20, min: 0 },
    isPublished: { type: Boolean, default: false },
    questions: { type: [questionSchema], default: [] },
    createdBy: { type: Schema.Types.ObjectId, ref: "User" },
  },
  { timestamps: true }
);

module.exports = mongoose.models.Quiz || mongoose.model("Quiz", quizSchema);
