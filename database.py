from pymongo import MongoClient
import certifi
import os
from dotenv import load_dotenv

load_dotenv()

MONGO_URI     = os.getenv("MONGO_URI", "mongodb+srv://limi_db_user:Cai0330...@cluster0.rz4get2.mongodb.net/")
DATABASE_NAME = "hack-arizona"

client = MongoClient(MONGO_URI, tlsCAFile=certifi.where())
db     = client[DATABASE_NAME]

# Collections
participants_col  = db["participants"]
attendance_col    = db["attendance_log"]
checkins_col      = db["checkin_responses"]
features_col      = db["features"]
risk_scores_col   = db["risk_scores"]
chat_history_col  = db["chat_history"]
resources_col     = db["resources"]

if __name__ == "__main__":
    count = participants_col.count_documents({})
    print(f"Connected to MongoDB Atlas. Participants: {count}")
