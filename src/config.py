import os
import firebase_admin
from firebase_admin import credentials, firestore

def initialize_firebase():
    try:
        # For local development
        cred = credentials.Certificate('serviceAccountKey.json')
        firebase_admin.initialize_app(cred)
    except FileNotFoundError:
        # For production (Cloud Run)
        import google.auth
        credentials, project = google.auth.default()
        firebase_admin.initialize_app(credentials=credentials)

def get_firestore_client():
    branch = os.getenv('BRANCH_NAME', 'main')
    project_name = os.getenv('PROJECT_NAME', 'default-project')
    return firestore.client().collection('projects').document(f'{project_name}-{branch}') 