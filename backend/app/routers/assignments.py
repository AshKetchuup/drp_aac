from typing import List
from fastapi import APIRouter, HTTPException, Depends
from datetime import datetime, timezone
from google.cloud.firestore_v1.base_query import FieldFilter

from app.db import db
from app.schemas import AssignmentCreate, AssignmentOut, StudentAssignmentOut
from app.auth import get_current_user

router = APIRouter(tags=["assignments"])

@router.post("/assignments", response_model=AssignmentOut)
def create_assignment(payload: AssignmentCreate, user: dict = Depends(get_current_user)):
    teacher_doc = db.collection("teachers").document(payload.teacher_id).get()
    if not teacher_doc.exists:
        raise HTTPException(status_code=404, detail="Teacher not found")

    student_doc = db.collection("students").document(payload.student_id).get()
    if not student_doc.exists:
        raise HTTPException(status_code=404, detail="Student not found")

    student_data = student_doc.to_dict()
    if student_data.get("teacher_id") != payload.teacher_id:
        raise HTTPException(status_code=403, detail="Student does not belong to this teacher")

    minigame_doc = db.collection("minigames").document(payload.minigame_id).get()
    if not minigame_doc.exists:
        raise HTTPException(status_code=404, detail="Minigame not found")

    assignment_data = {
        "teacher_id": payload.teacher_id,
        "student_id": payload.student_id,
        "minigame_id": payload.minigame_id,
        "status": "assigned",
        "assigned_at": datetime.now(timezone.utc)
    }

    _, doc_ref = db.collection("assignments").add(assignment_data)

    return AssignmentOut(id=doc_ref.id, **assignment_data)


@router.get("/students/{student_id}/assignments", response_model=List[StudentAssignmentOut])
def get_student_assignments(student_id: str, user: dict = Depends(get_current_user)):
    assignments_query = db.collection("assignments").where(
        filter=FieldFilter("student_id", "==", student_id)
    ).stream()

    result = []
    for doc in assignments_query:
        assignment_data = doc.to_dict()
        minigame_id = assignment_data.get("minigame_id")

        minigame_doc = db.collection("minigames").document(minigame_id).get()
        minigame_data = minigame_doc.to_dict() or {}

        result.append({
            "id": doc.id,
            "status": assignment_data.get("status"),
            "assigned_at": assignment_data.get("assigned_at"),
            "minigame": {
                "id": minigame_id,
                "title": minigame_data.get("title", ""),
                "description": minigame_data.get("description"),
                "category": minigame_data.get("category"),
            }
        })

    return result
