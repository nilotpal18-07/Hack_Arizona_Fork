"""Run once to seed demo data: python seed.py"""
from datetime import datetime, timedelta
from database import (attendance_col, checkins_col, participants_col,
                      resources_col)

# ── Participants ──────────────────────────────────────────────────────────────

PARTICIPANTS = [
    {
        "_id": "P001",
        "name": "Maria Garcia",
        "program_week": 4,
        "entry_pathway": "unemployment",
        "stated_goal": "get a stable job in food service",
        "barriers": ["transport", "childcare"],
        "housing_stable": 1,
        "transport_reliable": 0,
        "has_dependents": 1,
        "dependent_ages": [3, 7],
        "financial_stress_baseline": 4,
        "prior_food_experience": 0,
        "workforce_gap_years": 2,
    },
    {
        "_id": "P002",
        "name": "James Williams",
        "program_week": 6,
        "entry_pathway": "reentry",
        "stated_goal": "build a career and support my family",
        "barriers": ["housing", "financial"],
        "housing_stable": 0,
        "transport_reliable": 1,
        "has_dependents": 0,
        "dependent_ages": [],
        "financial_stress_baseline": 5,
        "prior_food_experience": 1,
        "workforce_gap_years": 5,
    },
    {
        "_id": "P003",
        "name": "Sandra Lopez",
        "program_week": 2,
        "entry_pathway": "long_term_absence",
        "stated_goal": "become a professional chef",
        "barriers": ["childcare"],
        "housing_stable": 1,
        "transport_reliable": 1,
        "has_dependents": 1,
        "dependent_ages": [5],
        "financial_stress_baseline": 3,
        "prior_food_experience": 0,
        "workforce_gap_years": 3,
    },
    {
        "_id": "P004",
        "name": "David Chen",
        "program_week": 8,
        "entry_pathway": "unemployment",
        "stated_goal": "open my own food truck someday",
        "barriers": ["financial"],
        "housing_stable": 1,
        "transport_reliable": 1,
        "has_dependents": 0,
        "dependent_ages": [],
        "financial_stress_baseline": 3,
        "prior_food_experience": 1,
        "workforce_gap_years": 1,
    },
    {
        "_id": "P005",
        "name": "Aisha Johnson",
        "program_week": 3,
        "entry_pathway": "reentry",
        "stated_goal": "provide stability for my kids",
        "barriers": ["transport", "housing", "childcare"],
        "housing_stable": 0,
        "transport_reliable": 0,
        "has_dependents": 1,
        "dependent_ages": [2, 8, 11],
        "financial_stress_baseline": 5,
        "prior_food_experience": 0,
        "workforce_gap_years": 4,
    },
    {
        "_id": "P006",
        "name": "Robert Martinez",
        "program_week": 5,
        "entry_pathway": "long_term_absence",
        "stated_goal": "get back on my feet and rebuild my life",
        "barriers": ["mental_health", "financial"],
        "housing_stable": 1,
        "transport_reliable": 1,
        "has_dependents": 0,
        "dependent_ages": [],
        "financial_stress_baseline": 4,
        "prior_food_experience": 0,
        "workforce_gap_years": 6,
    },
]

# ── Resources ─────────────────────────────────────────────────────────────────

RESOURCES = [
    {"barrier_type": "transport",     "name": "Sun Tran",                "phone": "(520) 792-9222", "website": "suntran.com",      "maps_query": "Sun Tran Tucson AZ"},
    {"barrier_type": "housing",       "name": "Primavera Foundation",    "phone": "(520) 882-8941", "website": "primavera.org",    "maps_query": "Primavera Foundation Tucson AZ"},
    {"barrier_type": "childcare",     "name": "Child and Family Resources", "phone": "(520) 881-8940", "website": "cfraz.org",    "maps_query": "Child Family Resources Tucson AZ"},
    {"barrier_type": "mental_health", "name": "La Frontera",             "phone": "(520) 838-3910", "website": "lafrontera.org",  "maps_query": "La Frontera Tucson AZ"},
    {"barrier_type": "financial",     "name": "DES Childcare Subsidy",   "phone": "(855) 432-7587", "website": "des.az.gov",      "maps_query": "DES Arizona Tucson"},
    {"barrier_type": "childcare",     "name": "YMCA Southern Arizona",   "phone": "(520) 623-5511", "website": "ymcatucson.org",  "maps_query": "YMCA Tucson AZ"},
]

# ── Attendance patterns: index → present (1) or absent (0) ───────────────────
# Indices count from day 0 (oldest). Unlisted indices default to present=1.

ABSENCE_PATTERNS = {
    # P001: a couple of mid-program absences — manageable
    "P001": {3: 0, 11: 0, 16: 0},
    # P002: housing instability causes scattered absences
    "P002": {2: 0, 9: 0, 15: 0, 22: 0, 27: 0},
    # P003: mostly perfect attendance (week 2, fresh start)
    "P003": {4: 0},
    # P004: near-perfect, one early absence (week 8, thriving)
    "P004": {6: 0, 28: 0},
    # P005: HIGH RISK — 3 recent consecutive absences + 2 earlier gaps
    "P005": {4: 0, 9: 0, 12: 0, 13: 0, 14: 0},
    # P006: mental health challenges — 3 scattered absences
    "P006": {7: 0, 14: 0, 21: 0},
}

# ── Checkin data per participant: list of weekly checkins (oldest→newest) ─────

CHECKIN_DATA = {
    "P001": [
        {"housing_delta": 0, "transport_delta": -1, "caregiving_delta": 0,  "financial_stress": 4, "motivation_score": 3, "confidence_score": 3.0, "responded": 1},
        {"housing_delta": 0, "transport_delta": -1, "caregiving_delta": 1,  "financial_stress": 4, "motivation_score": 3, "confidence_score": 2.8, "responded": 1},
        {"housing_delta": 0, "transport_delta":  0, "caregiving_delta": 0,  "financial_stress": 3, "motivation_score": 4, "confidence_score": 3.5, "responded": 1},
        {"housing_delta": 0, "transport_delta": -1, "caregiving_delta": 0,  "financial_stress": 4, "motivation_score": 3, "confidence_score": 3.0, "responded": 1},
    ],
    "P002": [
        {"housing_delta": 0,  "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 5, "motivation_score": 2, "confidence_score": 2.5, "responded": 1},
        {"housing_delta": 1,  "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 5, "motivation_score": 2, "confidence_score": 2.0, "responded": 1},
        {"housing_delta": 1,  "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 5, "motivation_score": 3, "confidence_score": 2.5, "responded": 1},
        {"housing_delta": 0,  "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 4, "motivation_score": 3, "confidence_score": 3.0, "responded": 1},
        {"housing_delta": 0,  "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 4, "motivation_score": 3, "confidence_score": 3.0, "responded": 1},
        {"housing_delta": 1,  "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 5, "motivation_score": 2, "confidence_score": 2.0, "responded": 1},
    ],
    "P003": [
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 3, "motivation_score": 4, "confidence_score": 4.0, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 3, "motivation_score": 4, "confidence_score": 4.2, "responded": 1},
    ],
    "P004": [
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 3, "motivation_score": 4, "confidence_score": 4.0, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 2, "motivation_score": 5, "confidence_score": 4.5, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 2, "motivation_score": 5, "confidence_score": 4.8, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 2, "motivation_score": 5, "confidence_score": 4.8, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 3, "motivation_score": 4, "confidence_score": 4.5, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 2, "motivation_score": 5, "confidence_score": 5.0, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 2, "motivation_score": 5, "confidence_score": 5.0, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 2, "motivation_score": 5, "confidence_score": 5.0, "responded": 1},
    ],
    # P005: HIGH RISK — worsening barriers, low motivation, SMS non-response
    "P005": [
        {"housing_delta": 0,  "transport_delta": -1, "caregiving_delta": 1,  "financial_stress": 5, "motivation_score": 2, "confidence_score": 2.0, "responded": 1},
        {"housing_delta": 1,  "transport_delta": -1, "caregiving_delta": 1,  "financial_stress": 5, "motivation_score": 1, "confidence_score": 1.5, "responded": 0},
        {"housing_delta": 1,  "transport_delta":  1, "caregiving_delta": 1,  "financial_stress": 5, "motivation_score": 1, "confidence_score": 1.2, "responded": 0},
    ],
    "P006": [
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 4, "motivation_score": 3, "confidence_score": 2.8, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 4, "motivation_score": 2, "confidence_score": 2.5, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 3, "motivation_score": 3, "confidence_score": 3.0, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 4, "motivation_score": 2, "confidence_score": 2.5, "responded": 1},
        {"housing_delta": 0, "transport_delta": 0, "caregiving_delta": 0, "financial_stress": 4, "motivation_score": 3, "confidence_score": 2.8, "responded": 1},
    ],
}


# ── Helpers ───────────────────────────────────────────────────────────────────

def get_weekdays_back(n_days: int) -> list[datetime]:
    """Return n_days weekday datetimes going backwards from today (oldest first)."""
    dates, d = [], datetime.now().replace(hour=9, minute=0, second=0, microsecond=0)
    while len(dates) < n_days:
        if d.weekday() < 5:
            dates.append(d)
        d -= timedelta(days=1)
    return list(reversed(dates))


# ── Seed functions ────────────────────────────────────────────────────────────

def seed_attendance(pid: str, program_week: int) -> None:
    pattern = ABSENCE_PATTERNS.get(pid, {})
    dates   = get_weekdays_back(program_week * 5)
    records = [
        {
            "participant_id": pid,
            "date":           d,
            "present":        pattern.get(i, 1),
            "partial_day":    0,
        }
        for i, d in enumerate(dates)
    ]
    attendance_col.insert_many(records)
    print(f"  Seeded {len(records)} attendance records for {pid}")


def seed_checkins(pid: str) -> None:
    data    = CHECKIN_DATA.get(pid, [])
    n_weeks = len(data)
    records = [
        {
            "participant_id":  pid,
            "week_number":     week + 1,
            "housing_delta":   row["housing_delta"],
            "transport_delta": row["transport_delta"],
            "caregiving_delta": row["caregiving_delta"],
            "financial_stress": row["financial_stress"],
            "motivation_score": row["motivation_score"],
            "confidence_score": row["confidence_score"],
            "responded":        row["responded"],
            "submitted_at":     datetime.now() - timedelta(weeks=n_weeks - week - 1),
        }
        for week, row in enumerate(data)
    ]
    if records:
        checkins_col.insert_many(records)
    print(f"  Seeded {len(records)} checkin records for {pid}")


def run_seed() -> None:
    if participants_col.count_documents({}) > 0:
        print("Data already seeded — skipping.")
        return

    print("Seeding participants...")
    participants_col.insert_many(PARTICIPANTS)

    print("Seeding attendance logs...")
    for p in PARTICIPANTS:
        seed_attendance(p["_id"], p["program_week"])

    print("Seeding checkin responses...")
    for p in PARTICIPANTS:
        seed_checkins(p["_id"])

    print("Seeding Tucson resources...")
    resources_col.insert_many(RESOURCES)

    print("Seed complete.")


if __name__ == "__main__":
    run_seed()
