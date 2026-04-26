# Run with: uvicorn model2_chatbot:app --reload --port 7001
# Requires ANTHROPIC_API_KEY environment variable

from contextlib import asynccontextmanager
from datetime import datetime, timezone

import anthropic
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from database import (chat_history_col, checkins_col, participants_col,
                      risk_scores_col)
from seed import run_seed

MODEL = "claude-sonnet-4-6"

DISTRESS_KEYWORDS = [
    "quit", "drop out", "can't do this", "overwhelmed",
    "homeless", "lost my ride", "no childcare",
]

_client: anthropic.Anthropic | None = None


# ── Participant context from MongoDB ──────────────────────────────────────────

def get_participant_context(participant_id: str) -> dict | None:
    participant = participants_col.find_one({"_id": participant_id})
    if not participant:
        return None

    risk = risk_scores_col.find_one(
        {"participant_id": participant_id},
        sort=[("_id", -1)],
    )

    checkin = checkins_col.find_one(
        {"participant_id": participant_id},
        sort=[("_id", -1)],
    )

    history = list(
        chat_history_col.find({"participant_id": participant_id})
        .sort("_id", -1).limit(6)
    )
    history = list(reversed(history))

    return {
        "participant": participant or {},
        "risk":        risk        or {},
        "checkin":     checkin     or {},
        "history":     history,
    }


# ── System prompt ─────────────────────────────────────────────────────────────

def build_system_prompt(context: dict) -> str:
    p        = context["participant"]
    r        = context["risk"]
    c        = context["checkin"]
    barriers = ", ".join(p.get("barriers", [])) or "none listed"
    risk_line = (
        f"{r.get('alert_level', 'unknown')} ({r.get('risk_score', '?')}/100)"
        if r else "not yet assessed"
    )

    return f"""You are Mise, a warm supportive assistant for {p.get('name', 'this participant')}, \
currently in week {p.get('program_week', '?')} of 10 at Caridad Community Kitchen, \
a free culinary training program in Tucson Arizona run by Community Food Bank of Southern Arizona. \
The program runs Monday–Friday 8:30am–3:30pm and teaches knife skills, food safety, sanitation, \
quantity meal prep, and leads to a ServSafe certification.

Their stated goal: {p.get('stated_goal', 'complete the program')}
Known barriers: {barriers}
Current risk level: {risk_line}
Latest motivation score: {c.get('motivation_score', '?')}/5
Latest financial stress: {c.get('financial_stress', '?')}/5

BEHAVIORAL RULES
- If risk level is red, be extra attentive — ask what specific help they need today.
- If motivation score is below 3, warmly reference their stated goal to reconnect them with their why.
- If they mention transport problems: Sun Tran (520) 792-9222 | suntran.com
- If they mention housing problems: Primavera Foundation (520) 882-8941 | primavera.org
- If they mention childcare problems: Child and Family Resources (520) 881-8940 | cfraz.org
- If they mention feeling overwhelmed or mental health: La Frontera (520) 838-3910 | lafrontera.org
- If they mention financial stress: DES subsidy (855) 432-7587 | des.az.gov
- Be warm, concise, never preachy. 1–3 short paragraphs max.
- Never repeat the same resource twice in one conversation.
- Always end with an open question to keep them engaged.
- Always address them by their first name.

STRICT SCOPE
You are ONLY here to support participants of Caridad Community Kitchen / Community Food Bank of Southern Arizona.
Do NOT answer general knowledge questions, coding help, math, or anything unrelated to the participant's \
wellbeing, attendance, barriers, or culinary training journey.
If asked something off-topic, redirect warmly: "I'm Mise, your Caridad Kitchen coach — I'm only here \
to support your journey through the program. Is there anything going on with training or life outside \
the kitchen I can help with?\""""


# ── Sentiment & coordinator flagging ─────────────────────────────────────────

_DISTRESS_WORDS = {
    "struggling", "overwhelmed", "stressed", "scared", "quit", "quitting",
    "drop out", "dropping out", "can't do this", "worried", "frustrated",
    "hopeless", "giving up", "too hard", "homeless", "no food", "evicted",
}

_POSITIVE_WORDS = {
    "great", "good", "happy", "excited", "love it", "doing well",
    "feeling better", "thanks", "thank you", "amazing", "awesome",
    "proud", "confident", "ready",
}


def detect_sentiment(message: str) -> str:
    lower = message.lower()
    if any(w in lower for w in _DISTRESS_WORDS):
        return "struggling"
    if any(w in lower for w in _POSITIVE_WORDS):
        return "positive"
    return "neutral"


def should_flag_coordinator(message: str) -> bool:
    lower = message.lower()
    return any(kw in lower for kw in DISTRESS_KEYWORDS)


def write_chat_to_mongo(participant_id: str, role: str, content: str,
                        flag: bool, sentiment: str) -> None:
    chat_history_col.insert_one({
        "participant_id":   participant_id,
        "role":             role,
        "content":          content,
        "flag_coordinator": int(flag),
        "sentiment":        sentiment,
        "timestamp":        datetime.now(timezone.utc),
    })


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    participant_id: str
    message: str


# ── FastAPI app ───────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    global _client
    run_seed()
    _client = anthropic.Anthropic()
    print("Mise chatbot ready.")
    yield


app = FastAPI(title="Caridad Kitchen Chatbot API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/chat")
def post_chat(body: ChatRequest):
    ctx = get_participant_context(body.participant_id)
    if not ctx:
        raise HTTPException(status_code=404, detail=f"Participant {body.participant_id} not found.")

    messages = [
        {"role": h["role"], "content": h["content"]}
        for h in ctx["history"]
    ] + [{"role": "user", "content": body.message}]

    sentiment = detect_sentiment(body.message)
    flagged   = should_flag_coordinator(body.message)

    write_chat_to_mongo(body.participant_id, "user", body.message, flagged, sentiment)

    response = _client.messages.create(
        model=MODEL,
        max_tokens=512,
        system=build_system_prompt(ctx),
        messages=messages,
    )
    reply = response.content[0].text

    write_chat_to_mongo(body.participant_id, "assistant", reply, False, "neutral")

    return {
        "participant_id":   body.participant_id,
        "reply":            reply,
        "sentiment":        sentiment,
        "flag_coordinator": flagged,
    }


@app.get("/chat-history/{participant_id}")
def get_history(participant_id: str):
    rows = list(
        chat_history_col.find({"participant_id": participant_id})
        .sort("timestamp", -1).limit(20)
    )
    rows = list(reversed(rows))
    return [
        {
            "role":             r["role"],
            "content":          r["content"],
            "sentiment":        r.get("sentiment"),
            "flag_coordinator": bool(r.get("flag_coordinator")),
            "timestamp":        r["timestamp"].isoformat() if r.get("timestamp") else None,
        }
        for r in rows
    ]
