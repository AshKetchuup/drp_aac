import os
from firebase_admin import credentials, initialize_app, firestore
from google.auth.credentials import AnonymousCredentials

if os.getenv("TESTING") == "true":
    app = initialize_app(credential=AnonymousCredentials(), options={"projectId": "mock-id"})
else:
    cred = credentials.Certificate(os.getenv("FIREBASE_CREDENTIALS_PATH"))
    app = initialize_app(cred)

db = firestore.client()
