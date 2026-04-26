import pandas as pd
from mongo_config import db

def fetch(collection_name):
    docs = list(db[collection_name].find({}, {"_id": 0}))
    return pd.DataFrame(docs)

def fetch_all():
    collections = [
        "cohorts", "coordinators", "participants",
        "baseline_assessments", "weekly_checkins",
        "chapter_confidence", "attendance",
        "dashboard_activity", "risk_scores",
        "risk_events", "interventions",
    ]
    return {name: fetch(name) for name in collections}

if __name__ == "__main__":
    data = fetch_all()
    for name, df in data.items():
        print(f"{name}: {len(df)} documents")
