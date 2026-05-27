from typing import List
from fastapi import APIRouter
from google.cloud.firestore_v1.base_query import FieldFilter

from app.db import db
from app.schemas import StudentOut

router = APIRouter(tags=["students"])

@router.get("/teachers/{teacher_id}/students", response_model=List[StudentOut])
def get_students(teacher_id: str):
    query = db.collection("students").where(filter=FieldFilter("teacher_id", "==", teacher_id))
    
    return [
        StudentOut(id=doc.id, **doc.to_dict()) 
        for doc in query.stream()
    ]
