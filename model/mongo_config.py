import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
DB_NAME   = "hack_arizona"

client = MongoClient(MONGO_URI)
db     = client[DB_NAME]
