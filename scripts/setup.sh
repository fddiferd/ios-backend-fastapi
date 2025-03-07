#!/bin/bash

# Load environment variables
source .env

# Authenticate with service account
gcloud auth activate-service-account --key-file=serviceAccountKey.json
gcloud config set project $GCP_PROJECT_ID

# Create Firestore database (if needed)
gcloud firestore databases create --region=$REGION

# Deploy FastAPI service
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
SERVICE_NAME="$GCP_PROJECT_ID-$BRANCH_NAME"

gcloud builds submit --tag gcr.io/$GCP_PROJECT_ID/api:$BRANCH_NAME
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$GCP_PROJECT_ID/api:$BRANCH_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated

# Get Cloud Run URL
URL=$(gcloud run services describe $SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --format 'value(status.url)')

# Store URL in Firestore
python3 -c "
from firebase_admin import firestore, credentials
import firebase_admin
cred = credentials.Certificate('serviceAccountKey.json')
firebase_admin.initialize_app(cred)
db = firestore.client()
db.collection('projects').document('$SERVICE_NAME').set({
    'status': 'active',
    'url': '$URL',
    'branch': '$BRANCH_NAME'
})
" 