from fastapi import FastAPI
from google.cloud import firestore
import os

app = FastAPI()

# Determine environment
environment = os.getenv("ENVIRONMENT", "local")

# Initialize Firestore
db = firestore.Client()

def get_collection():
    if environment == "production":
        return db.collection("prod_data")
    elif environment == "staging":
        return db.collection("staging_data")
    else:
        # For local development, use branch name or user-specific collection
        branch = os.getenv("BRANCH_NAME", "local_dev")
        return db.collection(f"dev_data").document(branch).collection("data")

@app.get("/data")
async def get_data():
    collection = get_collection()
    # Your data fetching logic here
    return {"message": "Data from " + environment} 