# Run with: uvicorn model1_risk:app --reload --port 7000

import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone

import joblib
import numpy as np
import pandas as pd
import shap
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from database import (attendance_col, checkins_col, features_col,
                      participants_col, risk_scores_col)
from seed import run_seed

MODEL_PATH  = "model.pkl"
SCALER_PATH = "scaler.pkl"
XTRAIN_PATH = "X_train_scaled.pkl"

FEATURES = [
    "consecutive_absences",
    "sms_nonresponse_streak",
    "housing_delta",
    "transport_delta",
    "confidence_score",
    "financial_stress",
    "program_week",
    "caregiving_delta",
]

FEATURES_ALL = FEATURES + ["absence_flag", "sms_flag", "housing_fin_flag"]

_model: LogisticRegression | None = None
_scaler: StandardScaler | None = None
_X_train_scaled: np.ndarray | None = None


# ── Synthetic data (for training only) ───────────────────────────────────────

def _add_flags(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["absence_flag"]     = (df["consecutive_absences"] >= 3).astype(int)
    df["sms_flag"]         = (df["sms_nonresponse_streak"] >= 4).astype(int)
    df["housing_fin_flag"] = ((df["housing_delta"] == 1) & (df["financial_stress"] >= 4)).astype(int)
    return df


def _engineer_input(data: dict) -> dict:
    return {
        **data,
        "absence_flag":     int(data["consecutive_absences"] >= 3),
        "sms_flag":         int(data["sms_nonresponse_streak"] >= 4),
        "housing_fin_flag": int(data["housing_delta"] == 1 and data["financial_stress"] >= 4),
    }


def generate_data(n: int = 1000, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    df = pd.DataFrame({
        "consecutive_absences":   rng.integers(0, 11, n),
        "sms_nonresponse_streak": rng.integers(0, 8, n),
        "housing_delta":          rng.choice([-1, 0, 1], n),
        "transport_delta":        rng.choice([-1, 0, 1], n),
        "confidence_score":       np.round(rng.uniform(1.0, 5.0, n), 1),
        "financial_stress":       rng.integers(1, 6, n),
        "program_week":           rng.integers(1, 11, n),
        "caregiving_delta":       rng.choice([-1, 0, 1], n),
    })
    label_arr = (
        (df["consecutive_absences"] >= 3)
        | (df["sms_nonresponse_streak"] >= 4)
        | ((df["housing_delta"] == 1) & (df["financial_stress"] >= 4))
    ).to_numpy().astype(int)
    noise = rng.random(n) < 0.10
    label_arr[noise] = 1 - label_arr[noise]
    df["dropout"] = label_arr
    return _add_flags(df)


# ── Model training ────────────────────────────────────────────────────────────

def train_model() -> dict:
    global _model, _scaler, _X_train_scaled

    df = generate_data()
    X, y = df[FEATURES_ALL], df["dropout"]
    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    scaler = StandardScaler()
    X_tr_s = scaler.fit_transform(X_tr)
    X_te_s = scaler.transform(X_te)
    model  = LogisticRegression(max_iter=1000, random_state=42, C=5)
    model.fit(X_tr_s, y_tr)

    y_pred = model.predict(X_te_s)
    print(f"  Accuracy:  {accuracy_score(y_te, y_pred):.4f}")
    print(f"  Precision: {precision_score(y_te, y_pred, zero_division=0):.4f}")
    print(f"  Recall:    {recall_score(y_te, y_pred, zero_division=0):.4f}")
    print(f"  F1:        {f1_score(y_te, y_pred, zero_division=0):.4f}")

    joblib.dump(model,  MODEL_PATH)
    joblib.dump(scaler, SCALER_PATH)
    joblib.dump(X_tr_s, XTRAIN_PATH)
    _model, _scaler, _X_train_scaled = model, scaler, X_tr_s
    return {"status": "trained", "n_train": len(X_tr), "n_test": len(X_te)}


def load_artifacts() -> None:
    global _model, _scaler, _X_train_scaled
    _model          = joblib.load(MODEL_PATH)
    _scaler         = joblib.load(SCALER_PATH)
    _X_train_scaled = joblib.load(XTRAIN_PATH)


# ── SHAP explainability ───────────────────────────────────────────────────────

def _feature_label(feature: str, val) -> str:
    if feature == "absence_flag":
        return "missed 3+ consecutive sessions (threshold)"
    if feature == "sms_flag":
        return "4+ days without SMS response (threshold)"
    if feature == "housing_fin_flag":
        return "housing worsened + high financial stress (combined)"
    return {
        "consecutive_absences":   f"missed {val} sessions",
        "sms_nonresponse_streak": f"no SMS reply for {val} days",
        "housing_delta":          "housing situation worsened",
        "transport_delta":        "transport flagged unreliable",
        "confidence_score":       f"confidence score dropped to {val}",
        "financial_stress":       "financial stress level high",
        "program_week":           f"week {val} in program",
        "caregiving_delta":       "caregiving burden increased",
    }.get(feature, feature)


def shap_top3(input_dict: dict) -> list[dict]:
    x_scaled  = _scaler.transform(pd.DataFrame([input_dict])[FEATURES_ALL])
    explainer = shap.LinearExplainer(_model, _X_train_scaled)
    raw = explainer.shap_values(x_scaled)
    sv  = np.asarray(raw[1] if isinstance(raw, list) and len(raw) == 2 else raw).flatten()

    score     = compute_risk_score(input_dict)
    pos_total = sum(s for s in sv if s > 0) or 1e-9
    neg_total = sum(abs(s) for s in sv if s < 0) or 1e-9

    impacts = [
        (feat, round((sv[i] / pos_total) * score) if sv[i] >= 0
         else -round((abs(sv[i]) / neg_total) * (100 - score)))
        for i, feat in enumerate(FEATURES_ALL)
    ]
    impacts.sort(key=lambda t: abs(t[1]), reverse=True)

    return [
        {
            "factor": _feature_label(feat, input_dict.get(feat, "")),
            "impact": f"+{pts} pts" if pts >= 0 else f"{pts} pts",
        }
        for feat, pts in impacts[:3]
    ]


# ── Risk score helpers ────────────────────────────────────────────────────────

def compute_risk_score(input_dict: dict) -> int:
    x_scaled = _scaler.transform(pd.DataFrame([input_dict])[FEATURES_ALL])
    return round(float(_model.predict_proba(x_scaled)[0][1]) * 100)


def get_alert_level(score: int) -> str:
    if score >= 70:
        return "red"
    if score >= 40:
        return "yellow"
    return "green"


_ACTIONS = {
    "red":    "Contact participant immediately",
    "yellow": "Schedule check-in call",
    "green":  "No immediate action required",
}


# ── Feature pipeline from MongoDB ─────────────────────────────────────────────

def get_features_from_mongo(participant_id: str) -> dict:
    feature = features_col.find_one(
        {"participant_id": participant_id},
        sort=[("_id", -1)],
    )
    if feature:
        return feature

    attendance = list(
        attendance_col.find({"participant_id": participant_id})
        .sort("date", -1).limit(10)
    )
    checkins = list(
        checkins_col.find({"participant_id": participant_id})
        .sort("_id", -1).limit(5)
    )

    absences = 0
    for a in attendance:
        if a.get("present") == 0:
            absences += 1
        else:
            break

    sms_streak = 0
    for c in checkins:
        if c.get("responded") == 0:
            sms_streak += 1
        else:
            break

    latest      = checkins[0] if checkins else {}
    participant = participants_col.find_one({"_id": participant_id})
    program_week = participant.get("program_week", 1) if participant else 1

    return {
        "participant_id":         participant_id,
        "consecutive_absences":   absences,
        "sms_nonresponse_streak": sms_streak,
        "housing_delta":          latest.get("housing_delta", 0),
        "transport_delta":        latest.get("transport_delta", 0),
        "caregiving_delta":       latest.get("caregiving_delta", 0),
        "financial_stress":       latest.get("financial_stress", 2),
        "confidence_score":       latest.get("confidence_score", 3.0),
        "motivation_score":       latest.get("motivation_score", 3),
        "program_week":           program_week,
    }


def write_risk_score_to_mongo(participant_id: str, week: int, score: int,
                               alert: str, shap: list[dict], action: str) -> None:
    risk_scores_col.insert_one({
        "participant_id":     participant_id,
        "week_number":        week,
        "risk_score":         score,
        "alert_level":        alert,
        "shap_factor_1":      shap[0]["factor"] if len(shap) > 0 else "",
        "shap_factor_2":      shap[1]["factor"] if len(shap) > 1 else "",
        "shap_factor_3":      shap[2]["factor"] if len(shap) > 2 else "",
        "recommended_action": action,
        "scored_at":          datetime.now(timezone.utc),
    })


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class PredictRequest(BaseModel):
    participant_id: str


# ── FastAPI app ───────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    run_seed()
    if not os.path.exists(MODEL_PATH):
        print("No saved model found — auto-training on startup...")
        train_model()
    else:
        load_artifacts()
        print("Model artifacts loaded from disk.")
    yield


app = FastAPI(title="Caridad Kitchen Dropout Risk API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/train")
def post_train():
    return train_model()


@app.post("/predict")
def post_predict(body: PredictRequest):
    if _model is None:
        raise HTTPException(status_code=503, detail="Model not loaded. POST /train first.")

    participant = participants_col.find_one({"_id": body.participant_id})
    if not participant:
        raise HTTPException(status_code=404, detail=f"Participant {body.participant_id} not found.")

    raw_features = get_features_from_mongo(body.participant_id)
    engineered   = _engineer_input(raw_features)
    score        = compute_risk_score(engineered)
    level        = get_alert_level(score)
    action       = _ACTIONS[level]
    explanation  = shap_top3(engineered)

    write_risk_score_to_mongo(body.participant_id, participant.get("program_week", 1),
                              score, level, explanation, action)
    return {
        "participant_id":     body.participant_id,
        "risk_score":         score,
        "alert_level":        level,
        "shap_explanation":   explanation,
        "recommended_action": action,
    }


@app.get("/risk-scores")
def get_risk_scores():
    pipeline = [
        {"$sort": {"scored_at": -1}},
        {"$group": {"_id": "$participant_id", "doc": {"$first": "$$ROOT"}}},
        {"$replaceRoot": {"newRoot": "$doc"}},
        {"$sort": {"risk_score": -1}},
    ]
    scores = list(risk_scores_col.aggregate(pipeline))
    result = []
    for s in scores:
        p = participants_col.find_one({"_id": s["participant_id"]}) or {}
        result.append({
            "participant_id":     s["participant_id"],
            "name":               p.get("name", "Unknown"),
            "program_week":       p.get("program_week"),
            "risk_score":         s.get("risk_score"),
            "alert_level":        s.get("alert_level"),
            "shap_factor_1":      s.get("shap_factor_1"),
            "shap_factor_2":      s.get("shap_factor_2"),
            "shap_factor_3":      s.get("shap_factor_3"),
            "recommended_action": s.get("recommended_action"),
            "scored_at":          s["scored_at"].isoformat() if s.get("scored_at") else None,
        })
    return result


@app.post("/predict-all")
def post_predict_all():
    if _model is None:
        raise HTTPException(status_code=503, detail="Model not loaded. POST /train first.")

    participants = list(participants_col.find({}))
    results = []

    for p in participants:
        pid = p["_id"]
        try:
            raw_features = get_features_from_mongo(pid)
            engineered   = _engineer_input(raw_features)
            score        = compute_risk_score(engineered)
            level        = get_alert_level(score)
            action       = _ACTIONS[level]
            explanation  = shap_top3(engineered)

            write_risk_score_to_mongo(pid, p.get("program_week", 1),
                                      score, level, explanation, action)
            results.append({"participant_id": pid, "name": p.get("name"),
                            "risk_score": score, "alert_level": level})
        except Exception as e:
            results.append({"participant_id": pid, "name": p.get("name"), "error": str(e)})

    return {"scored": len(results), "results": results}
